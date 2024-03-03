/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OMail
import docspell.common._
import docspell.restapi.model._
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s.QueryParam
import docspell.store.records.{RUserEmail, RUserImap}

import emil.javamail.syntax._
import emil.{MailAddress, SSLType}
import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object MailSettingsRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root / "smtp" :? QueryParam.QueryOpt(q) =>
        for {
          list <- backend.mail.getSmtpSettings(user.account.userId, q.map(_.q))
          res = list.map(convert)
          resp <- Ok(EmailSettingsList(res.toList))
        } yield resp

      case GET -> Root / "imap" :? QueryParam.QueryOpt(q) =>
        for {
          list <- backend.mail.getImapSettings(user.account.userId, q.map(_.q))
          res = list.map(convert)
          resp <- Ok(ImapSettingsList(res.toList))
        } yield resp

      case GET -> Root / "smtp" / Ident(name) =>
        (for {
          ems <- backend.mail.findSmtpSettings(user.account.userId, name)
          resp <- OptionT.liftF(Ok(convert(ems)))
        } yield resp).getOrElseF(NotFound())

      case GET -> Root / "imap" / Ident(name) =>
        (for {
          ems <- backend.mail.findImapSettings(user.account.userId, name)
          resp <- OptionT.liftF(Ok(convert(ems)))
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / "smtp" =>
        (for {
          in <- OptionT.liftF(req.as[EmailSettings])
          ru = makeSmtpSettings(in)
          up <- OptionT.liftF(
            ru.traverse(r => backend.mail.createSmtpSettings(user.account.userId, r))
          )
          resp <- OptionT.liftF(
            Ok(
              up.fold(
                err => BasicResult(success = false, err),
                ar => Conversions.basicResult(ar, "Mail settings stored.")
              )
            )
          )
        } yield resp).getOrElseF(NotFound())

      case req @ POST -> Root / "imap" =>
        (for {
          in <- OptionT.liftF(req.as[ImapSettings])
          ru = makeImapSettings(in)
          up <- OptionT.liftF(
            ru.traverse(r => backend.mail.createImapSettings(user.account.userId, r))
          )
          resp <- OptionT.liftF(
            Ok(
              up.fold(
                err => BasicResult(success = false, err),
                ar => Conversions.basicResult(ar, "Mail settings stored.")
              )
            )
          )
        } yield resp).getOrElseF(NotFound())

      case req @ PUT -> Root / "smtp" / Ident(name) =>
        (for {
          in <- OptionT.liftF(req.as[EmailSettings])
          ru = makeSmtpSettings(in)
          up <- OptionT.liftF(
            ru.traverse(r =>
              backend.mail.updateSmtpSettings(user.account.userId, name, r)
            )
          )
          resp <- OptionT.liftF(
            Ok(
              up.fold(
                err => BasicResult(success = false, err),
                n =>
                  if (n > 0) BasicResult(success = true, "Mail settings stored.")
                  else BasicResult(success = false, "Mail settings could not be saved")
              )
            )
          )
        } yield resp).getOrElseF(NotFound())

      case req @ PUT -> Root / "imap" / Ident(name) =>
        (for {
          in <- OptionT.liftF(req.as[ImapSettings])
          ru = makeImapSettings(in)
          up <- OptionT.liftF(
            ru.traverse(r =>
              backend.mail.updateImapSettings(user.account.userId, name, r)
            )
          )
          resp <- OptionT.liftF(
            Ok(
              up.fold(
                err => BasicResult(success = false, err),
                n =>
                  if (n > 0) BasicResult(success = true, "Mail settings stored.")
                  else BasicResult(success = false, "Mail settings could not be saved")
              )
            )
          )
        } yield resp).getOrElseF(NotFound())

      case DELETE -> Root / "smtp" / Ident(name) =>
        for {
          n <- backend.mail.deleteSmtpSettings(user.account.userId, name)
          resp <- Ok(
            if (n > 0) BasicResult(success = true, "Mail settings removed")
            else BasicResult(success = false, "Mail settings could not be removed")
          )
        } yield resp

      case DELETE -> Root / "imap" / Ident(name) =>
        for {
          n <- backend.mail.deleteImapSettings(user.account.userId, name)
          resp <- Ok(
            if (n > 0) BasicResult(success = true, "Mail settings removed")
            else BasicResult(success = false, "Mail settings could not be removed")
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

  def convert(ru: RUserImap): ImapSettings =
    ImapSettings(
      ru.name,
      ru.imapHost,
      ru.imapPort,
      ru.imapUser,
      ru.imapPassword,
      ru.imapSsl.name,
      !ru.imapCertCheck,
      ru.imapOAuth2
    )

  def makeSmtpSettings(ems: EmailSettings): Either[String, OMail.SmtpSettings] = {
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

  def makeImapSettings(ims: ImapSettings): Either[String, OMail.ImapSettings] =
    for {
      sslt <- SSLType.fromString(ims.sslType)
    } yield OMail.ImapSettings(
      ims.name,
      ims.imapHost,
      ims.imapPort,
      ims.imapUser,
      ims.imapPassword,
      sslt,
      !ims.ignoreCertificates,
      ims.useOAuth
    )
}
