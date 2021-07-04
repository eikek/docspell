/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops._
import docspell.common.Ident
import docspell.common.MakePreviewArgs
import docspell.restapi.model._
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s.BinaryUtil
import docspell.restserver.http4s.{QueryParam => QP}
import docspell.restserver.webapp.Webjars

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._

object AttachmentRoutes {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    def withResponseHeaders(resp: F[Response[F]])(
        data: OItemSearch.BinaryData[F]
    ): F[Response[F]] =
      BinaryUtil.withResponseHeaders[F](dsl, resp)(data)

    def makeByteResp(data: OItemSearch.BinaryData[F]): F[Response[F]] =
      BinaryUtil.makeByteResp(dsl)(data)

    HttpRoutes.of {
      case HEAD -> Root / Ident(id) =>
        for {
          fileData <- backend.itemSearch.findAttachment(id, user.account.collective)
          resp <-
            fileData
              .map(data => withResponseHeaders(Ok())(data))
              .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case req @ GET -> Root / Ident(id) =>
        for {
          fileData <- backend.itemSearch.findAttachment(id, user.account.collective)
          inm     = req.headers.get[`If-None-Match`].flatMap(_.tags)
          matches = BinaryUtil.matchETag(fileData.map(_.meta), inm)
          resp <-
            fileData
              .map { data =>
                if (matches) withResponseHeaders(NotModified())(data)
                else makeByteResp(data)
              }
              .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case HEAD -> Root / Ident(id) / "original" =>
        for {
          fileData <- backend.itemSearch.findAttachmentSource(id, user.account.collective)
          resp <-
            fileData
              .map(data => withResponseHeaders(Ok())(data))
              .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case req @ GET -> Root / Ident(id) / "original" =>
        for {
          fileData <- backend.itemSearch.findAttachmentSource(id, user.account.collective)
          inm     = req.headers.get[`If-None-Match`].flatMap(_.tags)
          matches = BinaryUtil.matchETag(fileData.map(_.meta), inm)
          resp <-
            fileData
              .map { data =>
                if (matches) withResponseHeaders(NotModified())(data)
                else makeByteResp(data)
              }
              .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case HEAD -> Root / Ident(id) / "archive" =>
        for {
          fileData <-
            backend.itemSearch.findAttachmentArchive(id, user.account.collective)
          resp <-
            fileData
              .map(data => withResponseHeaders(Ok())(data))
              .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case req @ GET -> Root / Ident(id) / "archive" =>
        for {
          fileData <-
            backend.itemSearch.findAttachmentArchive(id, user.account.collective)
          inm     = req.headers.get[`If-None-Match`].flatMap(_.tags)
          matches = BinaryUtil.matchETag(fileData.map(_.meta), inm)
          resp <-
            fileData
              .map { data =>
                if (matches) withResponseHeaders(NotModified())(data)
                else makeByteResp(data)
              }
              .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case req @ GET -> Root / Ident(id) / "preview" :? QP.WithFallback(flag) =>
        def notFound =
          NotFound(BasicResult(false, "Not found"))
        for {
          fileData <-
            backend.itemSearch.findAttachmentPreview(id, user.account.collective)
          inm      = req.headers.get[`If-None-Match`].flatMap(_.tags)
          matches  = BinaryUtil.matchETag(fileData.map(_.meta), inm)
          fallback = flag.getOrElse(false)
          resp <-
            fileData
              .map { data =>
                if (matches) withResponseHeaders(NotModified())(data)
                else makeByteResp(data)
              }
              .getOrElse(
                if (fallback) BinaryUtil.noPreview(req.some).getOrElseF(notFound)
                else notFound
              )
        } yield resp

      case HEAD -> Root / Ident(id) / "preview" =>
        for {
          fileData <-
            backend.itemSearch.findAttachmentPreview(id, user.account.collective)
          resp <-
            fileData
              .map(data => withResponseHeaders(Ok())(data))
              .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case POST -> Root / Ident(id) / "preview" =>
        for {
          res <- backend.item.generatePreview(
            MakePreviewArgs.replace(id),
            user.account,
            true
          )
          resp <- Ok(
            Conversions.basicResult(res, "Generating preview image task submitted.")
          )
        } yield resp

      case GET -> Root / Ident(id) / "view" =>
        // this route exists to provide a stable url
        // it redirects currently to viewerjs
        val attachUrl = s"/api/v1/sec/attachment/${id.id}"
        val path      = s"/app/assets${Webjars.viewerjs}/ViewerJS/index.html#$attachUrl"
        SeeOther(Location(Uri(path = Uri.Path.unsafeFromString(path))))

      case GET -> Root / Ident(id) / "meta" =>
        for {
          rm <- backend.itemSearch.findAttachmentMeta(id, user.account.collective)
          md = rm.map(Conversions.mkAttachmentMeta)
          resp <- md.map(Ok(_)).getOrElse(NotFound(BasicResult(false, "Not found.")))
        } yield resp

      case req @ POST -> Root / Ident(id) / "name" =>
        for {
          nn   <- req.as[OptionalText]
          res  <- backend.item.setAttachmentName(id, nn.text, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Name updated."))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          n <- backend.item.deleteAttachment(id, user.account.collective)
          res =
            if (n == 0) BasicResult(false, "Attachment not found")
            else BasicResult(true, "Attachment deleted.")
          resp <- Ok(res)
        } yield resp
    }
  }
}
