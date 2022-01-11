/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.joexapi.model.BasicResult
import docspell.jsonminiq.JsonMiniQuery
import docspell.notification.api.EventType
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s.ClientRequestInfo

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.server.Router

object NotificationRoutes {

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
          list <- backend.notification.listChannels(user.account)
          data = list.map(NotificationChannel.convert)
          resp <- Ok(data)
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          res <- backend.notification.deleteChannel(id, user.account)
          resp <- Ok(Conversions.basicResult(res, "Channel deleted"))
        } yield resp

      case req @ POST -> Root =>
        for {
          input <- req.as[NotificationChannel]
          ch <- Sync[F].pure(NotificationChannel.convert(input)).rethrow
          res <- backend.notification.createChannel(ch, user.account)
          resp <- Ok(Conversions.basicResult(res, "Channel created"))
        } yield resp

      case req @ PUT -> Root =>
        for {
          input <- req.as[NotificationChannel]
          ch <- Sync[F].pure(NotificationChannel.convert(input)).rethrow
          res <- backend.notification.updateChannel(ch, user.account)
          resp <- Ok(Conversions.basicResult(res, "Channel created"))
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
          list <- backend.notification.listHooks(user.account)
          data = list.map(Converters.convertHook)
          resp <- Ok(data)
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          res <- backend.notification.deleteHook(id, user.account)
          resp <- Ok(Conversions.basicResult(res, "Hook deleted."))
        } yield resp

      case req @ POST -> Root =>
        for {
          input <- req.as[NotificationHook]
          hook <- Sync[F].pure(Converters.convertHook(input)).rethrow
          res <- backend.notification.createHook(hook, user.account)
          resp <- Ok(Conversions.basicResult(res, "Hook created"))
        } yield resp

      case req @ PUT -> Root =>
        for {
          input <- req.as[NotificationHook]
          hook <- Sync[F].pure(Converters.convertHook(input)).rethrow
          res <- backend.notification.updateHook(hook, user.account)
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
          ch <- Sync[F]
            .pure(
              input.channel.left
                .map(_ => new Exception(s"ChannelRefs not allowed for testing"))
                .flatMap(NotificationChannel.convert)
            )
            .rethrow
          baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
          res <- backend.notification.sendSampleEvent(
            input.events.headOption.getOrElse(EventType.all.head),
            ch,
            user.account,
            baseUrl.some
          )
          resp <- Ok(NotificationChannelTestResult(res.success, res.logMessages.toList))
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
            BadRequest(BasicResult(false, s"Unable to render message: $err"))
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
        h.channel.map(NotificationChannel.convert),
        h.allEvents,
        h.eventFilter,
        h.events
      )

    def convertHook(h: NotificationHook): Either[Throwable, ONotification.Hook] =
      h.channel match {
        case Left(cref) =>
          Right(
            ONotification.Hook(
              h.id,
              h.enabled,
              Left(cref),
              h.allEvents,
              h.eventFilter,
              h.events
            )
          )
        case Right(channel) =>
          NotificationChannel
            .convert(channel)
            .map(ch =>
              ONotification
                .Hook(h.id, h.enabled, Right(ch), h.allEvents, h.eventFilter, h.events)
            )
      }

  }
}
