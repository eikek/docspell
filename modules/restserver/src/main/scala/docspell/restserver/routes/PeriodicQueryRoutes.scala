/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.{NonEmptyList, OptionT}
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.MailAddressCodec
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.notification.api.{ChannelRef, PeriodicQueryArgs}
import docspell.query.ItemQueryParser
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.{Conversions, NonEmptyListSupport}
import docspell.restserver.http4s.ClientRequestInfo
import docspell.scheduler.usertask._

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object PeriodicQueryRoutes extends MailAddressCodec with NonEmptyListSupport {

  def apply[F[_]: Async](
      cfg: Config,
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    val ut = backend.userTask
    import dsl._

    HttpRoutes.strict {
      case GET -> Root =>
        ut.getPeriodicQuery(UserTaskScope(user.account))
          .evalMap(task => taskToSettings(task))
          .compile
          .toVector
          .flatMap(Ok(_))

      case GET -> Root / Ident(id) =>
        (for {
          task <- ut.findPeriodicQuery(id, UserTaskScope(user.account))
          res <- OptionT.liftF(taskToSettings(task))
          resp <- OptionT.liftF(Ok(res))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / "startonce" =>
        for {
          data <- req.as[PeriodicQuerySettings]
          newId <- Ident.randomId[F]
          task <- makeTask(newId, getBaseUrl(cfg, req), user.account, data)
          res <-
            ut.executeNow(UserTaskScope(user.account), None, task)
              .attempt
              .map(Conversions.basicResult(_, "Submitted successfully."))
          resp <- Ok(res)
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          res <-
            ut.deleteTask(UserTaskScope(user.account), id)
              .attempt
              .map(Conversions.basicResult(_, "Deleted successfully"))
          resp <- Ok(res)
        } yield resp

      case req @ PUT -> Root =>
        def run(data: PeriodicQuerySettings) =
          for {
            task <- makeTask(data.id, getBaseUrl(cfg, req), user.account, data)
            res <-
              ut.submitPeriodicQuery(UserTaskScope(user.account), None, task)
                .attempt
                .map(Conversions.basicResult(_, "Saved successfully"))
            resp <- Ok(res)
          } yield resp
        for {
          data <- req.as[PeriodicQuerySettings]
          resp <-
            if (data.id.isEmpty)
              Ok(BasicResult(success = false, "Empty id is not allowed"))
            else run(data)
        } yield resp

      case req @ POST -> Root =>
        for {
          data <- req.as[PeriodicQuerySettings]
          newId <- Ident.randomId[F]
          task <- makeTask(newId, getBaseUrl(cfg, req), user.account, data)
          res <-
            ut.submitPeriodicQuery(UserTaskScope(user.account), None, task)
              .attempt
              .map(Conversions.basicResult(_, "Saved successfully."))
          resp <- Ok(res)
        } yield resp

    }
  }

  private def getBaseUrl[F[_]](cfg: Config, req: Request[F]) =
    ClientRequestInfo.getBaseUrl(cfg, req)

  def makeTask[F[_]: Sync](
      id: Ident,
      baseUrl: LenientUri,
      user: AccountInfo,
      settings: PeriodicQuerySettings
  ): F[UserTask[PeriodicQueryArgs]] =
    Sync[F]
      .pure(for {
        ch <- NonEmptyList
          .fromList(settings.channels)
          .toRight(new Exception(s"No channels found for: ${settings.channels}"))
        qstr <- settings.query match {
          case Some(q) =>
            ItemQueryParser
              .asString(q.expr)
              .left
              .map(err => new IllegalArgumentException(s"Query not renderable: $err"))
              .map(Option.apply)
          case None =>
            Right(None)
        }
        _ <-
          if (qstr.nonEmpty || settings.bookmark.nonEmpty) Right(())
          else Left(new IllegalArgumentException("No query or bookmark provided"))
      } yield (ch, qstr.map(ItemQueryString.apply)))
      .rethrow
      .map { case (channels, qstr) =>
        UserTask(
          id,
          PeriodicQueryArgs.taskName,
          settings.enabled,
          settings.schedule,
          settings.summary,
          PeriodicQueryArgs(
            user,
            channels.map(r => ChannelRef(r.id, r.channelType, r.name)),
            qstr,
            settings.bookmark,
            Some(baseUrl / "app" / "item"),
            settings.contentStart
          )
        )
      }

  def taskToSettings[F[_]: Sync](
      task: UserTask[PeriodicQueryArgs]
  ): F[PeriodicQuerySettings] =
    Sync[F].pure(
      PeriodicQuerySettings(
        task.id,
        task.enabled,
        task.summary,
        task.args.channels
          .map(c => NotificationChannelRef(c.id, c.channelType, c.name))
          .toList,
        task.timer,
        task.args.query.map(_.query).map(ItemQueryParser.parseUnsafe),
        task.args.bookmark,
        task.args.contentStart
      )
    )
}
