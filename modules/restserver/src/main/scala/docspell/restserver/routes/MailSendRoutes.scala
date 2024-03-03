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
import docspell.backend.ops.OMail.{AttachSelection, ItemMail, SendResult}
import docspell.common._
import docspell.restapi.model._

import emil.MailAddress
import emil.javamail.syntax._
import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object MailSendRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root / Ident(name) / Ident(id) =>
      for {
        in <- req.as[SimpleMail]
        mail = convertIn(id, in)
        res <- mail.traverse(m =>
          backend.mail.sendMail(user.account.userId, user.account.collectiveId, name, m)
        )
        resp <- res.fold(
          err => Ok(BasicResult(success = false, s"Invalid mail data: $err")),
          res => Ok(convertOut(res))
        )
      } yield resp
    }
  }

  def convertIn(item: Ident, s: SimpleMail): Either[String, ItemMail] =
    for {
      rec <- s.recipients.traverse(MailAddress.parse)
      cc <- s.cc.traverse(MailAddress.parse)
      bcc <- s.bcc.traverse(MailAddress.parse)
      sel =
        if (s.addAllAttachments) AttachSelection.All
        else AttachSelection.Selected(s.attachmentIds)
    } yield ItemMail(item, s.subject, rec, cc, bcc, s.body, sel)

  def convertOut(res: SendResult): BasicResult =
    res match {
      case SendResult.Success(_) =>
        BasicResult(success = true, "Mail sent.")
      case SendResult.SendFailure(ex) =>
        BasicResult(success = false, s"Mail sending failed: ${ex.getMessage}")
      case SendResult.StoreFailure(ex) =>
        BasicResult(
          success = false,
          s"Mail was sent, but could not be store to database: ${ex.getMessage}"
        )
      case SendResult.NotFound =>
        BasicResult(success = false, s"There was no mail-connection or item found.")
    }
}
