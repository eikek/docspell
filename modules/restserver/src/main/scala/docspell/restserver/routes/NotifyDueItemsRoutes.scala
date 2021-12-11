/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.MailAddressCodec
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.notification.api.PeriodicDueItemsArgs
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s.ClientRequestInfo
import docspell.store.usertask._

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object NotifyDueItemsRoutes extends MailAddressCodec {

  def apply[F[_]: Async](
      cfg: Config,
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    val ut = backend.userTask
    import dsl._

    HttpRoutes.of {
      case GET -> Root / Ident(id) =>
        (for {
          task <- ut.findNotifyDueItems(id, UserTaskScope(user.account))
          res <- OptionT.liftF(taskToSettings(backend, task))
          resp <- OptionT.liftF(Ok(res))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / "startonce" =>
        for {
          data <- req.as[PeriodicDueItemsSettings]
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
        def run(data: PeriodicDueItemsSettings) =
          for {
            task <- makeTask(data.id, getBaseUrl(cfg, req), user.account, data)
            res <-
              ut.submitNotifyDueItems(UserTaskScope(user.account), None, task)
                .attempt
                .map(Conversions.basicResult(_, "Saved successfully"))
            resp <- Ok(res)
          } yield resp
        for {
          data <- req.as[PeriodicDueItemsSettings]
          resp <-
            if (data.id.isEmpty) Ok(BasicResult(false, "Empty id is not allowed"))
            else run(data)
        } yield resp

      case req @ POST -> Root =>
        for {
          data <- req.as[PeriodicDueItemsSettings]
          newId <- Ident.randomId[F]
          task <- makeTask(newId, getBaseUrl(cfg, req), user.account, data)
          res <-
            ut.submitNotifyDueItems(UserTaskScope(user.account), None, task)
              .attempt
              .map(Conversions.basicResult(_, "Saved successfully."))
          resp <- Ok(res)
        } yield resp

      case GET -> Root =>
        ut.getNotifyDueItems(UserTaskScope(user.account))
          .evalMap(task => taskToSettings(backend, task))
          .compile
          .toVector
          .flatMap(Ok(_))
    }
  }

  private def getBaseUrl[F[_]](cfg: Config, req: Request[F]) =
    ClientRequestInfo.getBaseUrl(cfg, req)

  def makeTask[F[_]: Sync](
      id: Ident,
      baseUrl: LenientUri,
      user: AccountId,
      settings: PeriodicDueItemsSettings
  ): F[UserTask[PeriodicDueItemsArgs]] =
    Sync[F].pure(NotificationChannel.convert(settings.channel)).rethrow.map { channel =>
      UserTask(
        id,
        PeriodicDueItemsArgs.taskName,
        settings.enabled,
        settings.schedule,
        settings.summary,
        PeriodicDueItemsArgs(
          user,
          Right(channel),
          settings.remindDays,
          if (settings.capOverdue) Some(settings.remindDays)
          else None,
          settings.tagsInclude.map(_.id),
          settings.tagsExclude.map(_.id),
          Some(baseUrl / "app" / "item")
        )
      )
    }

  def taskToSettings[F[_]: Sync](
      backend: BackendApp[F],
      task: UserTask[PeriodicDueItemsArgs]
  ): F[PeriodicDueItemsSettings] =
    for {
      tinc <- backend.tag.loadAll(task.args.tagsInclude)
      texc <- backend.tag.loadAll(task.args.tagsExclude)

      ch <- task.args.channel match {
        case Right(c) => NotificationChannel.convert(c).pure[F]
        case Left(ref) =>
          Sync[F].raiseError(
            new IllegalStateException(s"ChannelRefs are not supported: $ref")
          )
      }

    } yield PeriodicDueItemsSettings(
      task.id,
      task.enabled,
      task.summary,
      ch,
      task.timer,
      task.args.remindDays,
      task.args.daysBack.isDefined,
      tinc.map(Conversions.mkTag).toList,
      texc.map(Conversions.mkTag).toList
    )
}
