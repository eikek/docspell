/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect.Async
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.restapi.model._
import docspell.restserver.conv.NonEmptyListSupport

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object AttachmentMultiRoutes extends NonEmptyListSupport {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {

    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root / "delete" =>
      for {
        json <- req.as[IdList]
        attachments <- requireNonEmpty(json.ids)
        n <- backend.item.deleteAttachmentMultiple(attachments, user.account.collectiveId)
        res = BasicResult(
          n > 0,
          if (n > 0) "Attachment(s) deleted" else "Attachment deletion failed."
        )
        resp <- Ok(res)
      } yield resp
    }
  }

}
