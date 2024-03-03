/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.{Kleisli, OptionT}
import cats.effect._
import cats.syntax.all._

import docspell.backend.BackendApp
import docspell.backend.auth.{AuthToken, ShareToken}
import docspell.backend.ops.ODownloadAll.model._
import docspell.backend.ops.OShare.ShareQuery
import docspell.common.{DownloadAllType, Ident}
import docspell.joexapi.model.BasicResult
import docspell.query.ItemQuery
import docspell.restapi.model.{DownloadAllRequest, DownloadAllSummary}
import docspell.restserver.Config.DownloadAllCfg
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s.BinaryUtil

import org.http4s.circe.CirceEntityCodec._
import org.http4s.dsl.Http4sDsl
import org.http4s.{HttpRoutes, Request}

object DownloadAllRoutes {

  def forShare[F[_]: Async](
      cfg: DownloadAllCfg,
      backend: BackendApp[F],
      token: ShareToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    val find: Kleisli[OptionT[F, *], Request[F], ShareQuery] =
      Kleisli(_ => backend.share.findShareQuery(token.id))

    find.flatMap { share =>
      HttpRoutes.of[F] {
        case req @ POST -> Root / "prefetch" =>
          for {
            input <- req.as[DownloadAllRequest]
            query = ItemQuery.Expr.and(share.query.expr, input.query.expr)
            result <- backend.downloadAll.getSummary(
              share.account,
              DownloadRequest(
                ItemQuery(query, None),
                DownloadAllType.Converted,
                cfg.maxFiles,
                cfg.maxSize
              )
            )
            resp <- Ok(convertSummary(result))
          } yield resp

        case req @ POST -> Root / "submit" =>
          for {
            input <- req.as[DownloadAllRequest]
            query = ItemQuery.Expr.and(share.query.expr, input.query.expr)
            result <- backend.downloadAll.submit(
              share.account,
              DownloadRequest(
                ItemQuery(query, None),
                DownloadAllType.Converted,
                cfg.maxFiles,
                cfg.maxSize
              )
            )
            resp <- Ok(convertSummary(result))
          } yield resp

        case req @ GET -> Root / "file" / Ident(id) =>
          for {
            data <- backend.downloadAll.getFile(share.account.collectiveId, id)
            resp <- BinaryUtil.respond(dsl, req)(data)
          } yield resp
      }
    }
  }

  def apply[F[_]: Async](
      cfg: DownloadAllCfg,
      backend: BackendApp[F],
      token: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "prefetch" =>
        for {
          input <- req.as[DownloadAllRequest]
          result <- backend.downloadAll.getSummary(
            token.account,
            DownloadRequest(input.query, input.fileType, cfg.maxFiles, cfg.maxSize)
          )
          resp <- Ok(convertSummary(result))
        } yield resp

      case req @ POST -> Root / "submit" =>
        for {
          input <- req.as[DownloadAllRequest]
          result <- backend.downloadAll.submit(
            token.account,
            DownloadRequest(input.query, input.fileType, cfg.maxFiles, cfg.maxSize)
          )
          resp <- Ok(convertSummary(result))
        } yield resp

      case req @ GET -> Root / "file" / Ident(id) =>
        for {
          data <- backend.downloadAll.getFile(token.account.collectiveId, id)
          resp <- BinaryUtil.respond(dsl, req)(data)
        } yield resp

      case HEAD -> Root / "file" / Ident(id) =>
        for {
          data <- backend.downloadAll.getFile(token.account.collectiveId, id)
          resp <- BinaryUtil.respondHead(dsl)(data)
        } yield resp

      case DELETE -> Root / "file" / Ident(id) =>
        for {
          _ <- backend.downloadAll.deleteFile(id)
          resp <- Ok(BasicResult(success = true, "File deleted."))
        } yield resp

      case PUT -> Root / "cancel" / Ident(id) =>
        for {
          res <- backend.downloadAll.cancelDownload(token.account.collectiveId, id)
          resp <- Ok(Conversions.basicResult(res))
        } yield resp
    }
  }

  private def convertSummary(result: DownloadSummary): DownloadAllSummary =
    DownloadAllSummary(
      id = result.id,
      fileCount = result.fileCount,
      uncompressedSize = result.uncompressedSize,
      state = result.state
    )
}
