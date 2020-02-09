package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import cats.data.OptionT
import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.circe.CirceEntityEncoder._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OMail.Sent
import docspell.common._
import docspell.restapi.model._
import docspell.store.EmilUtil

object SentMailRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root / "item" / Ident(id) =>
        for {
          all  <- backend.mail.getSentMailsForItem(user.account, id)
          resp <- Ok(SentMails(all.map(convert).toList))
        } yield resp

      case GET -> Root / "mail" / Ident(mailId) =>
        (for {
          mail <- backend.mail.getSentMail(user.account, mailId)
          resp <- OptionT.liftF(Ok(convert(mail)))
        } yield resp).getOrElseF(NotFound())

      case DELETE -> Root / "mail" / Ident(mailId) =>
        for {
          n    <- backend.mail.deleteSentMail(user.account, mailId)
          resp <- Ok(BasicResult(n > 0, s"Mails deleted: $n"))
        } yield resp
    }
  }

  def convert(s: Sent): SentMail =
    SentMail(
      s.id,
      s.senderLogin,
      s.connectionName,
      s.recipients.map(EmilUtil.mailAddressString),
      s.subject,
      s.body,
      s.created
    )
}
