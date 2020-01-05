package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.circe.CirceEntityDecoder._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.restapi.model._
import docspell.store.records.RUserEmail
import docspell.store.EmilUtil

object MailSettingsRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ GET -> Root =>
        val q = req.params.get("q").map(_.trim).filter(_.nonEmpty)
        for {
          list <- backend.mail.getSettings(user.account, q)
          res = list.map(convert)
          resp <- Ok(EmailSettingsList(res.toList))
        } yield resp

      case req @ POST -> Root =>
        for {
          in   <- req.as[EmailSettings]
          resp <- Ok(BasicResult(false, "not implemented"))
        } yield resp
    }

  }

  def convert(ru: RUserEmail): EmailSettings =
    EmailSettings(
      ru.name,
      ru.smtpHost,
      ru.smtpPort,
      ru.smtpUser,
      ru.smtpPassword,
      EmilUtil.mailAddressString(ru.mailFrom),
      ru.mailReplyTo.map(EmilUtil.mailAddressString _),
      EmilUtil.sslTypeString(ru.smtpSsl),
      !ru.smtpCertCheck
    )
}
