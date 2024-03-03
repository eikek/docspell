/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.{EitherT, NonEmptyList}
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.joexapi.model.BasicResult
import docspell.jsonminiq.JsonMiniQuery
import docspell.notification.api.{ChannelRef, EventType}
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.{Conversions, NonEmptyListSupport}
import docspell.restserver.http4s.ClientRequestInfo

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.server.Router

object NotificationRoutes extends NonEmptyListSupport {

  def apply[F[_]: Async](
      cfg: Config,
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] =
    Router(
      "channel" -> channels(backend, user),
      "hook" -> hooks(cfg, backend, user),
      "event" -> events(cfg, backend, user)
    )

  def channels[F[_]: Async](
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root =>
        for {
          list <- backend.notification.listChannels(user.account.userId)
          data = list.map(NotificationChannel.convert)
          resp <- Ok(data)
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          res <- backend.notification.deleteChannel(id, user.account.userId)
          resp <- Ok(Conversions.basicResult(res, "Channel deleted"))
        } yield resp

      case req @ POST -> Root =>
        for {
          input <- req.as[NotificationChannel]
          ch <- Sync[F].pure(NotificationChannel.convert(input))
          resp <- EitherT
            .fromEither[F](ch)
            .semiflatMap { c =>
              backend.notification
                .createChannel(c, user.account.userId)
                .map(res => Conversions.basicResult(res, "Channel created"))
            }
            .foldF(ex => BadRequest(BasicResult(success = false, ex.getMessage)), Ok(_))
        } yield resp

      case req @ PUT -> Root =>
        for {
          input <- req.as[NotificationChannel]
          ch <- Sync[F].pure(NotificationChannel.convert(input))
          resp <- EitherT
            .fromEither[F](ch)
            .semiflatMap { c =>
              backend.notification
                .updateChannel(c, user.account.userId)
                .map(res => Conversions.basicResult(res, "Channel created"))
            }
            .foldF(ex => BadRequest(BasicResult(success = false, ex.getMessage)), Ok(_))
        } yield resp
    }
  }

  def hooks[F[_]: Async](
      cfg: Config,
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root =>
        for {
          list <- backend.notification.listHooks(user.account.userId)
          data = list.map(Converters.convertHook)
          resp <- Ok(data)
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          res <- backend.notification.deleteHook(id, user.account.userId)
          resp <- Ok(Conversions.basicResult(res, "Hook deleted."))
        } yield resp

      case req @ POST -> Root =>
        for {
          input <- req.as[NotificationHook]
          hook <- Sync[F].pure(Converters.convertHook(input)).rethrow
          res <- backend.notification.createHook(hook, user.account.userId)
          resp <- Ok(Conversions.basicResult(res, "Hook created"))
        } yield resp

      case req @ PUT -> Root =>
        for {
          input <- req.as[NotificationHook]
          hook <- Sync[F].pure(Converters.convertHook(input)).rethrow
          res <- backend.notification.updateHook(hook, user.account.userId)
          resp <- Ok(Conversions.basicResult(res, "Hook updated"))
        } yield resp

      case req @ POST -> Root / "verifyJsonFilter" =>
        for {
          input <- req.as[StringValue]
          res = JsonMiniQuery.parse(input.value)
          resp <- Ok(BasicResult(res.isRight, res.fold(identity, _.unsafeAsString)))
        } yield resp

      case req @ POST -> Root / "sendTestEvent" =>
        for {
          input <- req.as[NotificationHook]
          ch <- requireNonEmpty(input.channels)
          baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
          res <- backend.notification.sendSampleEvent(
            input.events.headOption.getOrElse(EventType.all.head),
            ch.map(r => ChannelRef(r.id, r.channelType, r.name)),
            user.account,
            baseUrl.some
          )
          messages = res.logEvents.map(_.asString)
          resp <- Ok(NotificationChannelTestResult(res.success, messages.toList))
        } yield resp
    }
  }

  def events[F[_]: Async](
      cfg: Config,
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root / "sample" =>
      for {
        input <- req.as[NotificationSampleEventReq]
        baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
        data <- backend.notification.sampleEvent(
          input.eventType,
          user.account,
          baseUrl.some
        )
        resp <- data.asJsonWithMessage match {
          case Right(m) => Ok(m)
          case Left(err) =>
            BadRequest(BasicResult(success = false, s"Unable to render message: $err"))
        }
      } yield resp
    }
  }

  object Converters {

    import docspell.backend.ops.ONotification

    def convertHook(h: ONotification.Hook): NotificationHook =
      NotificationHook(
        h.id,
        h.enabled,
        h.channels.map(c => NotificationChannelRef(c.id, c.channelType, c.name)),
        h.allEvents,
        h.eventFilter,
        h.events
      )

    def convertHook(h: NotificationHook): Either[Throwable, ONotification.Hook] =
      NonEmptyList
        .fromList(h.channels)
        .toRight(new IllegalArgumentException(s"Empty channels not allowed!"))
        .map(_ =>
          ONotification.Hook(
            h.id,
            h.enabled,
            h.channels.map(c => ChannelRef(c.id, c.channelType, c.name)),
            h.allEvents,
            h.eventFilter,
            h.events
          )
        )

  }
}
