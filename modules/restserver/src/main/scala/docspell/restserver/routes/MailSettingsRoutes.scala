package docspell.restserver.routes

import cats.effect._
import cats.implicits._
import cats.data.OptionT
import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.circe.CirceEntityDecoder._
import emil.{MailAddress, SSLType}
import emil.javamail.syntax._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OMail
import docspell.common._
import docspell.restapi.model._
import docspell.store.records.RUserEmail
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s.QueryParam

object MailSettingsRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root :? QueryParam.QueryOpt(q) =>
        for {
          list <- backend.mail.getSettings(user.account, q.map(_.q))
          res = list.map(convert)
          resp <- Ok(EmailSettingsList(res.toList))
        } yield resp

      case GET -> Root / Ident(name) =>
        (for {
          ems  <- backend.mail.findSettings(user.account, name)
          resp <- OptionT.liftF(Ok(convert(ems)))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root =>
        (for {
          in <- OptionT.liftF(req.as[EmailSettings])
          ru = makeSettings(in)
          up <- OptionT.liftF(
            ru.traverse(r => backend.mail.createSettings(user.account, r))
          )
          resp <- OptionT.liftF(
            Ok(
              up.fold(
                err => BasicResult(false, err),
                ar => Conversions.basicResult(ar, "Mail settings stored.")
              )
            )
          )
        } yield resp).getOrElseF(NotFound())

      case req @ PUT -> Root / Ident(name) =>
        (for {
          in <- OptionT.liftF(req.as[EmailSettings])
          ru = makeSettings(in)
          up <- OptionT.liftF(
            ru.traverse(r => backend.mail.updateSettings(user.account, name, r))
          )
          resp <- OptionT.liftF(
            Ok(
              up.fold(
                err => BasicResult(false, err),
                n =>
                  if (n > 0) BasicResult(true, "Mail settings stored.")
                  else BasicResult(false, "Mail settings could not be saved")
              )
            )
          )
        } yield resp).getOrElseF(NotFound())

      case DELETE -> Root / Ident(name) =>
        for {
          n <- backend.mail.deleteSettings(user.account, name)
          resp <- Ok(
            if (n > 0) BasicResult(true, "Mail settings removed")
            else BasicResult(false, "Mail settings could not be removed")
          )
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
      ru.mailFrom.asUnicodeString,
      ru.mailReplyTo.map(_.asUnicodeString),
      ru.smtpSsl.name,
      !ru.smtpCertCheck
    )

  def makeSettings(ems: EmailSettings): Either[String, OMail.SmtpSettings] = {
    def readMail(str: String): Either[String, MailAddress] =
      MailAddress.parse(str).left.map(err => s"E-Mail address '$str' invalid: $err")

    def readMailOpt(str: Option[String]): Either[String, Option[MailAddress]] =
      str.traverse(readMail)

    for {
      from <- readMail(ems.from)
      repl <- readMailOpt(ems.replyTo)
      sslt <- SSLType.fromString(ems.sslType)
    } yield OMail.SmtpSettings(
      ems.name,
      ems.smtpHost,
      ems.smtpPort,
      ems.smtpUser,
      ems.smtpPassword,
      sslt,
      !ems.ignoreCertificates,
      from,
      repl
    )

  }
}
