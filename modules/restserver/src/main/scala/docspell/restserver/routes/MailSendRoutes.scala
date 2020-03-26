package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.circe.CirceEntityDecoder._
import emil.MailAddress
import emil.javamail.syntax._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OMail.{AttachSelection, ItemMail}
import docspell.backend.ops.SendResult
import docspell.common._
import docspell.restapi.model._

object MailSendRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / Ident(name) / Ident(id) =>
        for {
          in <- req.as[SimpleMail]
          mail = convertIn(id, in)
          res <- mail.traverse(m => backend.mail.sendMail(user.account, name, m))
          resp <- res.fold(
            err => Ok(BasicResult(false, s"Invalid mail data: $err")),
            res => Ok(convertOut(res))
          )
        } yield resp
    }
  }

  def convertIn(item: Ident, s: SimpleMail): Either[String, ItemMail] =
    for {
      rec     <- s.recipients.traverse(MailAddress.parse)
      fileIds <- s.attachmentIds.traverse(Ident.fromString)
      sel = if (s.addAllAttachments) AttachSelection.All
      else AttachSelection.Selected(fileIds)
    } yield ItemMail(item, s.subject, rec, s.body, sel)

  def convertOut(res: SendResult): BasicResult =
    res match {
      case SendResult.Success(_) =>
        BasicResult(true, "Mail sent.")
      case SendResult.SendFailure(ex) =>
        BasicResult(false, s"Mail sending failed: ${ex.getMessage}")
      case SendResult.StoreFailure(ex) =>
        BasicResult(
          false,
          s"Mail was sent, but could not be store to database: ${ex.getMessage}"
        )
      case SendResult.NotFound =>
        BasicResult(false, s"There was no mail-connection or item found.")
    }
}
