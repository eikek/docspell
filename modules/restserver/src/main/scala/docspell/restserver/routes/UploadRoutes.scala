/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.io.file.Files

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions._
import docspell.restserver.http4s.ResponseGenerator

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.log4s._

object UploadRoutes {
  private[this] val logger = getLogger

  def secured[F[_]: Async: Files](
      backend: BackendApp[F],
      cfg: Config,
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    val submitting =
      submitFiles[F](
        backend,
        cfg,
        Right(user.account.collectiveId),
        user.account.userId.some
      ) _

    HttpRoutes.of {
      case req @ POST -> Root / "item" =>
        submitting(req, None, Priority.High, dsl)

      case req @ POST -> Root / "item" / Ident(itemId) =>
        submitting(req, Some(itemId), Priority.High, dsl)
    }
  }

  def open[F[_]: Async: Files](backend: BackendApp[F], cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "item" / Ident(srcId) =>
        (for {
          _ <- OptionT(backend.collective.findEnabledSource(srcId))
          res <- OptionT.liftF(
            submitFiles(backend, cfg, Left(srcId), None)(req, None, Priority.Low, dsl)
          )
        } yield res).getOrElseF(NotFound())

      case req @ POST -> Root / "item" / Ident(itemId) / Ident(srcId) =>
        (for {
          _ <- OptionT(backend.collective.findEnabledSource(srcId))
          res <- OptionT.liftF(
            submitFiles(backend, cfg, Left(srcId), None)(
              req,
              Some(itemId),
              Priority.Low,
              dsl
            )
          )
        } yield res).getOrElseF(NotFound())
    }
  }

  private def submitFiles[F[_]: Async: Files](
      backend: BackendApp[F],
      cfg: Config,
      accOrSrc: Either[Ident, CollectiveId],
      userId: Option[Ident]
  )(
      req: Request[F],
      itemId: Option[Ident],
      prio: Priority,
      dsl: Http4sDsl[F]
  ): F[Response[F]] = {
    import dsl._

    val decodeMultipart =
      EntityDecoder
        .mixedMultipartResource(
          maxSizeBeforeWrite = 10 * 1024 * 1024
        )
        .evalMap(_.decode(req, strict = false).value)
        .rethrow

    decodeMultipart.use { multipart =>
      for {
        updata <- readMultipart(
          multipart,
          "webapp",
          logger,
          prio,
          cfg.backend.files.validMimeTypes
        )
        result <- backend.upload.submitEither(updata, accOrSrc, userId, itemId)
        res <- Ok(basicResult(result))
      } yield res
    }
  }
}
