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

import org.http4s.HttpRoutes
import org.http4s.dsl.Http4sDsl

object ShareAttachmentRoutes {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      token: ShareToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ GET -> Root / Ident(id) / "preview" =>
        for {
          fileData <-
            backend.share.findAttachmentPreview(id, token.id).value
          resp <- BinaryUtil.respond(dsl, req)(fileData)
        } yield resp

      case HEAD -> Root / Ident(id) / "preview" =>
        for {
          fileData <-
            backend.share.findAttachmentPreview(id, token.id).value
          resp <- BinaryUtil.respondHead(dsl)(fileData)
        } yield resp
    }
  }
}
