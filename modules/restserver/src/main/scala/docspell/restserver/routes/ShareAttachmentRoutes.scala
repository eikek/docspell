/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.ShareToken
import docspell.common._
import docspell.restserver.http4s.BinaryUtil
import docspell.restserver.webapp.Webjars

import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._

object ShareAttachmentRoutes {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: ShareToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case HEAD -> Root / Ident(id) =>
        for {
          fileData <- backend.share.findAttachment(id, token.id).value
          resp <- BinaryUtil.respondHead(dsl)(fileData)
        } yield resp

      case req @ GET -> Root / Ident(id) =>
        for {
          fileData <- backend.share.findAttachment(id, token.id).value
          resp <- BinaryUtil.respond(dsl, req)(fileData)
        } yield resp

      case GET -> Root / Ident(id) / "view" =>
        // this route exists to provide a stable url
        // it redirects currently to viewerjs
        val attachUrl = s"/api/v1/share/attachment/${id.id}"
        val path = s"/app/assets${Webjars.viewerjs}/index.html#$attachUrl"
        SeeOther(Location(Uri(path = Uri.Path.unsafeFromString(path))))

      case req @ GET -> Root / Ident(id) / "preview" =>
        for {
          fileData <- backend.share.findAttachmentPreview(id, token.id).value
          resp <- BinaryUtil.respondPreview(dsl, req)(fileData)
        } yield resp

      case HEAD -> Root / Ident(id) / "preview" =>
        for {
          fileData <- backend.share.findAttachmentPreview(id, token.id).value
          resp <- BinaryUtil.respondPreviewHead(dsl)(fileData)
        } yield resp
    }
  }
}
