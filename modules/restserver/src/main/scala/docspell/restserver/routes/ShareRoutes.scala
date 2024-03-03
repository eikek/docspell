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
import docspell.backend.ops.OShare
import docspell.backend.ops.OShare.{SendResult, ShareMail, VerifyResult}
import docspell.common.syntax.string._
import docspell.common.{Ident, Timestamp}
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.auth.ShareCookieData
import docspell.restserver.http4s.{ClientRequestInfo, QueryParam => QP, ResponseGenerator}

import emil.MailAddress
import emil.javamail.syntax._
import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object ShareRoutes {

  def manage[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root :? QP.Query(q) :? QP.OwningFlag(owning) =>
        val login = if (owning) Some(user.account.login) else None
        for {
          all <- backend.share.findAll(user.account.collectiveId, login, q.asNonBlank)
          now <- Timestamp.current[F]
          res <- Ok(ShareList(all.map(mkShareDetail(now))))
        } yield res

      case req @ POST -> Root =>
        for {
          data <- req.as[ShareData]
          share = mkNewShare(data, user)
          res <- backend.share.addNew(share)
          resp <- Ok(mkIdResult(res, "New share created."))
        } yield resp

      case GET -> Root / Ident(id) =>
        (for {
          share <- backend.share.findOne(id, user.account.collectiveId)
          now <- OptionT.liftF(Timestamp.current[F])
          resp <- OptionT.liftF(Ok(mkShareDetail(now)(share)))
        } yield resp).getOrElseF(NotFound())

      case req @ PUT -> Root / Ident(id) =>
        for {
          data <- req.as[ShareData]
          share = mkNewShare(data, user)
          updated <- backend.share.update(id, share, data.removePassword.getOrElse(false))
          resp <- Ok(mkBasicResult(updated, "Share updated."))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          del <- backend.share.delete(id, user.account.collectiveId)
          resp <- Ok(BasicResult(del, if (del) "Share deleted." else "Deleting failed."))
        } yield resp

      case req @ POST -> Root / "email" / "send" / Ident(name) =>
        for {
          in <- req.as[SimpleShareMail]
          mail = convertIn(in)
          res <- mail.traverse(m =>
            backend.share
              .sendMail(user.account.collectiveId, user.account.userId, name, m)
          )
          resp <- res.fold(
            err => Ok(BasicResult(success = false, s"Invalid mail data: $err")),
            res => Ok(convertOut(res))
          )
        } yield resp
    }
  }

  def verify[F[_]: Async](backend: BackendApp[F], cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root / "verify" =>
      for {
        secret <- req.as[ShareSecret]
        res <- backend.share
          .verify(cfg.auth.serverSecret)(secret.shareId, secret.password)
        resp <- res match {
          case VerifyResult.Success(token, name) =>
            val cd = ShareCookieData(token)
            Ok(
              ShareVerifyResult(
                success = true,
                token.asString,
                passwordRequired = false,
                "Success",
                name
              )
            )
              .map(cd.addCookie(ClientRequestInfo.getBaseUrl(cfg, req)))
          case VerifyResult.PasswordMismatch =>
            Ok(
              ShareVerifyResult(
                success = false,
                "",
                passwordRequired = true,
                "Failed",
                None
              )
            )
          case VerifyResult.NotFound =>
            Ok(
              ShareVerifyResult(
                success = false,
                "",
                passwordRequired = false,
                "Failed",
                None
              )
            )
          case VerifyResult.InvalidToken =>
            Ok(
              ShareVerifyResult(
                success = false,
                "",
                passwordRequired = false,
                "Failed",
                None
              )
            )
        }
      } yield resp
    }
  }

  def mkNewShare(data: ShareData, user: AuthToken): OShare.NewShare =
    OShare.NewShare(
      user.account.asAccountId,
      data.name,
      data.query,
      data.enabled,
      data.password,
      data.publishUntil
    )

  def mkIdResult(r: OShare.ChangeResult, msg: => String): IdResult =
    r match {
      case OShare.ChangeResult.Success(id) => IdResult(success = true, msg, id)
      case OShare.ChangeResult.PublishUntilInPast =>
        IdResult(success = false, "Until date must not be in the past", Ident.unsafe(""))
      case OShare.ChangeResult.NotFound =>
        IdResult(
          success = false,
          "Share not found or not owner. Only the owner can update a share.",
          Ident.unsafe("")
        )
      case OShare.ChangeResult.QueryWithFulltext =>
        IdResult(
          success = false,
          "Sorry, shares with fulltext queries are currently not supported.",
          Ident.unsafe("")
        )
    }

  def mkBasicResult(r: OShare.ChangeResult, msg: => String): BasicResult =
    r match {
      case OShare.ChangeResult.Success(_) => BasicResult(success = true, msg)
      case OShare.ChangeResult.PublishUntilInPast =>
        BasicResult(success = false, "Until date must not be in the past")
      case OShare.ChangeResult.NotFound =>
        BasicResult(
          success = false,
          "Share not found or not owner. Only the owner can update a share."
        )
      case OShare.ChangeResult.QueryWithFulltext =>
        BasicResult(
          success = false,
          "Sorry, shares with fulltext queries are currently not supported."
        )
    }

  def mkShareDetail(now: Timestamp)(r: OShare.ShareData): ShareDetail =
    ShareDetail(
      r.share.id,
      r.share.query,
      IdName(r.account.userId, r.account.login.id),
      r.share.name,
      r.share.enabled,
      r.share.publishAt,
      r.share.publishUntil,
      now > r.share.publishUntil,
      r.share.password.isDefined,
      r.share.views,
      r.share.lastAccess
    )

  def convertIn(s: SimpleShareMail): Either[String, ShareMail] =
    for {
      rec <- s.recipients.traverse(MailAddress.parse)
      cc <- s.cc.traverse(MailAddress.parse)
      bcc <- s.bcc.traverse(MailAddress.parse)
    } yield ShareMail(s.shareId, s.subject, rec, cc, bcc, s.body)

  def convertOut(res: SendResult): BasicResult =
    res match {
      case SendResult.Success(_) =>
        BasicResult(success = true, "Mail sent.")
      case SendResult.SendFailure(ex) =>
        BasicResult(success = false, s"Mail sending failed: ${ex.getMessage}")
      case SendResult.NotFound =>
        BasicResult(success = false, s"There was no mail-connection or item found.")
    }
}
