/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.syntax.all._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops._
import docspell.common.Ident
import docspell.common.MakePreviewArgs
import docspell.restapi.model._
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s.BinaryUtil
import docspell.restserver.webapp.Webjars
import docspell.scheduler.usertask.UserTaskScope

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
          fileData <- backend.itemSearch.findAttachment(id, user.account.collectiveId)
          resp <- BinaryUtil.respondHead(dsl)(fileData)
        } yield resp

      case req @ GET -> Root / Ident(id) =>
        for {
          fileData <- backend.itemSearch.findAttachment(id, user.account.collectiveId)
          resp <- BinaryUtil.respond[F](dsl, req)(fileData)
        } yield resp

      case HEAD -> Root / Ident(id) / "original" =>
        for {
          fileData <- backend.itemSearch.findAttachmentSource(
            id,
            user.account.collectiveId
          )
          resp <-
            fileData
              .map(data => withResponseHeaders(Ok())(data))
              .getOrElse(NotFound(BasicResult(success = false, "Not found")))
        } yield resp

      case req @ GET -> Root / Ident(id) / "original" =>
        for {
          fileData <- backend.itemSearch.findAttachmentSource(
            id,
            user.account.collectiveId
          )
          inm = req.headers.get[`If-None-Match`].flatMap(_.tags)
          matches = BinaryUtil.matchETag(fileData.map(_.meta), inm)
          resp <-
            fileData
              .map { data =>
                if (matches) withResponseHeaders(NotModified())(data)
                else makeByteResp(data)
              }
              .getOrElse(NotFound(BasicResult(success = false, "Not found")))
        } yield resp

      case HEAD -> Root / Ident(id) / "archive" =>
        for {
          fileData <-
            backend.itemSearch.findAttachmentArchive(id, user.account.collectiveId)
          resp <-
            fileData
              .map(data => withResponseHeaders(Ok())(data))
              .getOrElse(NotFound(BasicResult(success = false, "Not found")))
        } yield resp

      case req @ GET -> Root / Ident(id) / "archive" =>
        for {
          fileData <-
            backend.itemSearch.findAttachmentArchive(id, user.account.collectiveId)
          inm = req.headers.get[`If-None-Match`].flatMap(_.tags)
          matches = BinaryUtil.matchETag(fileData.map(_.meta), inm)
          resp <-
            fileData
              .map { data =>
                if (matches) withResponseHeaders(NotModified())(data)
                else makeByteResp(data)
              }
              .getOrElse(NotFound(BasicResult(success = false, "Not found")))
        } yield resp

      case req @ GET -> Root / Ident(id) / "preview" =>
        for {
          fileData <-
            backend.itemSearch.findAttachmentPreview(id, user.account.collectiveId)
          resp <- BinaryUtil.respondPreview(dsl, req)(fileData)
        } yield resp

      case HEAD -> Root / Ident(id) / "preview" =>
        for {
          fileData <-
            backend.itemSearch.findAttachmentPreview(id, user.account.collectiveId)
          resp <- BinaryUtil.respondPreviewHead(dsl)(fileData)
        } yield resp

      case POST -> Root / Ident(id) / "preview" =>
        for {
          res <- backend.item.generatePreview(
            MakePreviewArgs.replace(id),
            UserTaskScope(user.account)
          )
          resp <- Ok(
            Conversions.basicResult(res, "Generating preview image task submitted.")
          )
        } yield resp

      case GET -> Root / Ident(id) / "view" =>
        // this route exists to provide a stable url
        // it redirects currently to viewerjs
        val attachUrl = s"/api/v1/sec/attachment/${id.id}"
        val path =
          s"/app/assets${Webjars.pdfjsdistviewermin}/build/minified/web/viewer.html?file=$attachUrl"
        SeeOther(Location(Uri(path = Uri.Path.unsafeFromString(path))))

      case GET -> Root / Ident(id) / "meta" =>
        for {
          rm <- backend.itemSearch.findAttachmentMeta(id, user.account.collectiveId)
          md = rm.map(Conversions.mkAttachmentMeta)
          resp <- md
            .map(Ok(_))
            .getOrElse(NotFound(BasicResult(success = false, "Not found.")))
        } yield resp

      case req @ POST -> Root / Ident(id) / "name" =>
        for {
          nn <- req.as[OptionalText]
          res <- backend.item.setAttachmentName(id, nn.text, user.account.collectiveId)
          resp <- Ok(Conversions.basicResult(res, "Name updated."))
        } yield resp

      case req @ POST -> Root / Ident(id) / "extracted-text" =>
        (for {
          itemId <- OptionT(
            backend.itemSearch.findAttachment(id, user.account.collectiveId)
          ).map(_.ra.itemId)
          nn <- OptionT.liftF(req.as[OptionalText])
          newText = nn.text.getOrElse("").pure[F]
          _ <- OptionT.liftF(
            backend.attachment
              .setExtractedText(user.account.collectiveId, itemId, id, newText)
          )
          resp <- OptionT.liftF(
            Ok(BasicResult(success = true, "Extracted text updated."))
          )
        } yield resp)
          .getOrElseF(NotFound(BasicResult(success = false, "Attachment not found")))

      case DELETE -> Root / Ident(id) / "extracted-text" =>
        (for {
          itemId <- OptionT(
            backend.itemSearch.findAttachment(id, user.account.collectiveId)
          ).map(_.ra.itemId)
          _ <- OptionT.liftF(
            backend.attachment
              .setExtractedText(user.account.collectiveId, itemId, id, "".pure[F])
          )
          resp <- OptionT.liftF(
            Ok(BasicResult(success = true, "Extracted text cleared."))
          )
        } yield resp).getOrElseF(NotFound())

      case GET -> Root / Ident(id) / "extracted-text" =>
        (for {
          meta <- OptionT(
            backend.itemSearch.findAttachmentMeta(id, user.account.collectiveId)
          )
          resp <- OptionT.liftF(Ok(OptionalText(meta.content)))
        } yield resp)
          .getOrElseF(NotFound(BasicResult(success = false, "Attachment not found")))

      case DELETE -> Root / Ident(id) =>
        for {
          n <- backend.item.deleteAttachment(id, user.account.collectiveId)
          res =
            if (n == 0) BasicResult(success = false, "Attachment not found")
            else BasicResult(success = true, "Attachment deleted.")
          resp <- Ok(res)
        } yield resp
    }
  }

  def admin[F[_]: Async](backend: BackendApp[F]): HttpRoutes[F] = {
    val dsl = Http4sDsl[F]
    import dsl._

    HttpRoutes.of {
      case POST -> Root / "generatePreviews" =>
        for {
          res <- backend.item.generateAllPreviews(MakePreviewArgs.StoreMode.Replace)
          resp <- Ok(
            Conversions.basicResult(res, "Generate all previews task submitted.")
          )
        } yield resp

      case POST -> Root / "convertallpdfs" =>
        for {
          res <-
            backend.item.convertAllPdf(None, UserTaskScope.system)
          resp <- Ok(Conversions.basicResult(res, "Convert all PDFs task submitted"))
        } yield resp
    }
  }
}
