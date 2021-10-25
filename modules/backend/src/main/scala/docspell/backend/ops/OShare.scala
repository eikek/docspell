/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.PasswordCrypt
import docspell.backend.auth.ShareToken
import docspell.backend.ops.OItemSearch._
import docspell.backend.ops.OShare._
import docspell.backend.ops.OSimpleSearch.StringSearchResult
import docspell.common._
import docspell.query.ItemQuery.Expr
import docspell.query.ItemQuery.Expr.AttachId
import docspell.query.{FulltextExtract, ItemQuery}
import docspell.store.Store
import docspell.store.queries.SearchSummary
import docspell.store.records._

import emil._
import scodec.bits.ByteVector

trait OShare[F[_]] {

  def findAll(
      collective: Ident,
      ownerLogin: Option[Ident],
      query: Option[String]
  ): F[List[ShareData]]

  def delete(id: Ident, collective: Ident): F[Boolean]

  def addNew(share: OShare.NewShare): F[OShare.ChangeResult]

  def findOne(id: Ident, collective: Ident): OptionT[F, ShareData]

  def update(
      id: Ident,
      share: OShare.NewShare,
      removePassword: Boolean
  ): F[OShare.ChangeResult]

  // ---

  /** Verifies the given id and password and returns a authorization token on success. */
  def verify(key: ByteVector)(id: Ident, password: Option[Password]): F[VerifyResult]

  /** Verifies the authorization token. */
  def verifyToken(key: ByteVector)(token: String): F[VerifyResult]

  def findShareQuery(id: Ident): OptionT[F, ShareQuery]

  def findAttachmentPreview(
      attachId: Ident,
      shareId: Ident
  ): OptionT[F, AttachmentPreviewData[F]]

  def findAttachment(attachId: Ident, shareId: Ident): OptionT[F, AttachmentData[F]]

  def findItem(itemId: Ident, shareId: Ident): OptionT[F, ItemData]

  def searchSummary(
      settings: OSimpleSearch.StatsSettings
  )(shareId: Ident, q: ItemQueryString): OptionT[F, StringSearchResult[SearchSummary]]

  def sendMail(account: AccountId, connection: Ident, mail: ShareMail): F[SendResult]
}

object OShare {
  final case class ShareMail(
      shareId: Ident,
      subject: String,
      recipients: List[MailAddress],
      cc: List[MailAddress],
      bcc: List[MailAddress],
      body: String
  )

  sealed trait SendResult
  object SendResult {

    /** Mail was successfully sent and stored to db. */
    case class Success(msgId: String) extends SendResult

    /** There was a failure sending the mail. The mail is then not saved to db. */
    case class SendFailure(ex: Throwable) extends SendResult

    /** Something could not be found required for sending (mail configs, items etc). */
    case object NotFound extends SendResult
  }

  final case class ShareQuery(id: Ident, account: AccountId, query: ItemQuery)

  sealed trait VerifyResult {
    def toEither: Either[String, ShareToken] =
      this match {
        case VerifyResult.Success(token, _) =>
          Right(token)
        case _ => Left("Authentication failed.")
      }
  }
  object VerifyResult {
    case class Success(token: ShareToken, shareName: Option[String]) extends VerifyResult
    case object NotFound extends VerifyResult
    case object PasswordMismatch extends VerifyResult
    case object InvalidToken extends VerifyResult

    def success(token: ShareToken): VerifyResult = Success(token, None)
    def success(token: ShareToken, name: Option[String]): VerifyResult =
      Success(token, name)
    def notFound: VerifyResult = NotFound
    def passwordMismatch: VerifyResult = PasswordMismatch
    def invalidToken: VerifyResult = InvalidToken
  }

  final case class NewShare(
      account: AccountId,
      name: Option[String],
      query: ItemQuery,
      enabled: Boolean,
      password: Option[Password],
      publishUntil: Timestamp
  )

  sealed trait ChangeResult
  object ChangeResult {
    final case class Success(id: Ident) extends ChangeResult
    case object PublishUntilInPast extends ChangeResult
    case object NotFound extends ChangeResult
    case object QueryWithFulltext extends ChangeResult

    def success(id: Ident): ChangeResult = Success(id)
    def publishUntilInPast: ChangeResult = PublishUntilInPast
    def notFound: ChangeResult = NotFound
    def queryWithFulltext: ChangeResult = QueryWithFulltext
  }

  final case class ShareData(share: RShare, user: RUser)

  def apply[F[_]: Async](
      store: Store[F],
      itemSearch: OItemSearch[F],
      simpleSearch: OSimpleSearch[F],
      emil: Emil[F]
  ): OShare[F] =
    new OShare[F] {
      private[this] val logger = Logger.log4s[F](org.log4s.getLogger)

      def findAll(
          collective: Ident,
          ownerLogin: Option[Ident],
          query: Option[String]
      ): F[List[ShareData]] =
        store
          .transact(RShare.findAllByCollective(collective, ownerLogin, query))
          .map(_.map(ShareData.tupled))

      def delete(id: Ident, collective: Ident): F[Boolean] =
        store.transact(RShare.deleteByIdAndCid(id, collective)).map(_ > 0)

      def addNew(share: NewShare): F[ChangeResult] =
        for {
          curTime <- Timestamp.current[F]
          id <- Ident.randomId[F]
          user <- store.transact(RUser.findByAccount(share.account))
          pass = share.password.map(PasswordCrypt.crypt)
          record = RShare(
            id,
            user.map(_.uid).getOrElse(Ident.unsafe("-error-no-user-")),
            share.name,
            share.query,
            share.enabled,
            pass,
            curTime,
            share.publishUntil,
            0,
            None
          )
          res <-
            if (share.publishUntil < curTime) ChangeResult.publishUntilInPast.pure[F]
            else if (hasFulltext(share.query)) ChangeResult.queryWithFulltext.pure[F]
            else store.transact(RShare.insert(record)).map(_ => ChangeResult.success(id))
        } yield res

      def update(
          id: Ident,
          share: NewShare,
          removePassword: Boolean
      ): F[ChangeResult] =
        for {
          curTime <- Timestamp.current[F]
          user <- store.transact(RUser.findByAccount(share.account))
          record = RShare(
            id,
            user.map(_.uid).getOrElse(Ident.unsafe("-error-no-user-")),
            share.name,
            share.query,
            share.enabled,
            share.password.map(PasswordCrypt.crypt),
            Timestamp.Epoch,
            share.publishUntil,
            0,
            None
          )
          res <-
            if (share.publishUntil < curTime) ChangeResult.publishUntilInPast.pure[F]
            else if (hasFulltext(share.query)) ChangeResult.queryWithFulltext.pure[F]
            else
              store
                .transact(RShare.updateData(record, removePassword))
                .map(n => if (n > 0) ChangeResult.success(id) else ChangeResult.notFound)
        } yield res

      private def hasFulltext(iq: ItemQuery): Boolean =
        iq.findFulltext match {
          case FulltextExtract.Result.SuccessNoFulltext(_) => false
          case _                                           => true
        }

      def findOne(id: Ident, collective: Ident): OptionT[F, ShareData] =
        RShare
          .findOne(id, collective)
          .mapK(store.transform)
          .map(ShareData.tupled)

      def verify(
          key: ByteVector
      )(id: Ident, password: Option[Password]): F[VerifyResult] =
        RShare
          .findCurrentActive(id)
          .mapK(store.transform)
          .semiflatMap { case (share, _) =>
            val pwCheck =
              share.password.map(encPw => password.exists(PasswordCrypt.check(_, encPw)))

            // add the password (if existing) to the server secret key; this way the token
            // invalidates when the user changes the password
            val shareKey =
              share.password.map(pw => key ++ pw.asByteVector).getOrElse(key)

            val token = ShareToken
              .create(id, shareKey)
              .flatTap(_ => store.transact(RShare.incAccess(share.id)))
            pwCheck match {
              case Some(true)  => token.map(t => VerifyResult.success(t, share.name))
              case None        => token.map(t => VerifyResult.success(t, share.name))
              case Some(false) => VerifyResult.passwordMismatch.pure[F]
            }
          }
          .getOrElse(VerifyResult.notFound)

      def verifyToken(key: ByteVector)(token: String): F[VerifyResult] =
        ShareToken.fromString(token) match {
          case Right(st) =>
            RShare
              .findActivePassword(st.id)
              .mapK(store.transform)
              .semiflatMap { password =>
                val shareKey =
                  password.map(pw => key ++ pw.asByteVector).getOrElse(key)
                if (st.sigValid(shareKey)) VerifyResult.success(st).pure[F]
                else
                  logger.info(
                    s"Signature failure for share: ${st.id.id}"
                  ) *> VerifyResult.invalidToken.pure[F]
              }
              .getOrElse(VerifyResult.notFound)

          case Left(err) =>
            logger.debug(s"Invalid session token: $err") *>
              VerifyResult.invalidToken.pure[F]
        }

      def findShareQuery(id: Ident): OptionT[F, ShareQuery] =
        RShare
          .findCurrentActive(id)
          .mapK(store.transform)
          .map { case (share, user) =>
            ShareQuery(share.id, user.accountId, share.query)
          }

      def findAttachmentPreview(
          attachId: Ident,
          shareId: Ident
      ): OptionT[F, AttachmentPreviewData[F]] =
        for {
          sq <- findShareQuery(shareId)
          _ <- checkAttachment(sq, AttachId(attachId.id))
          res <- OptionT(
            itemSearch.findAttachmentPreview(attachId, sq.account.collective)
          )
        } yield res

      def findAttachment(attachId: Ident, shareId: Ident): OptionT[F, AttachmentData[F]] =
        for {
          sq <- findShareQuery(shareId)
          _ <- checkAttachment(sq, AttachId(attachId.id))
          res <- OptionT(itemSearch.findAttachment(attachId, sq.account.collective))
        } yield res

      def findItem(itemId: Ident, shareId: Ident): OptionT[F, ItemData] =
        for {
          sq <- findShareQuery(shareId)
          _ <- checkAttachment(sq, Expr.itemIdEq(itemId.id))
          res <- OptionT(itemSearch.findItem(itemId, sq.account.collective))
        } yield res

      /** Check whether the attachment with the given id is in the results of the given
        * share
        */
      private def checkAttachment(sq: ShareQuery, idExpr: Expr): OptionT[F, Unit] = {
        val checkQuery = Query(
          Query.Fix(sq.account, Some(sq.query.expr), None),
          Query.QueryExpr(idExpr)
        )
        OptionT(
          itemSearch
            .findItems(0)(checkQuery, Batch.limit(1))
            .map(_.headOption.map(_ => ()))
        ).flatTapNone(
          logger.info(
            s"Attempt to load unshared data '$idExpr' via share: ${sq.id.id}"
          )
        )
      }

      def searchSummary(
          settings: OSimpleSearch.StatsSettings
      )(
          shareId: Ident,
          q: ItemQueryString
      ): OptionT[F, StringSearchResult[SearchSummary]] =
        findShareQuery(shareId)
          .semiflatMap { share =>
            val fix = Query.Fix(share.account, Some(share.query.expr), None)
            simpleSearch
              .searchSummaryByString(settings)(fix, q)
              .map {
                case StringSearchResult.Success(summary) =>
                  StringSearchResult.Success(summary.onlyExisting)
                case other => other
              }
          }

      def sendMail(
          account: AccountId,
          connection: Ident,
          mail: ShareMail
      ): F[SendResult] = {
        val getSmtpSettings: OptionT[F, RUserEmail] =
          OptionT(store.transact(RUserEmail.getByName(account, connection)))

        def createMail(sett: RUserEmail): OptionT[F, Mail[F]] = {
          import _root_.emil.builder._

          OptionT.pure(
            MailBuilder.build(
              From(sett.mailFrom),
              Tos(mail.recipients),
              Ccs(mail.cc),
              Bccs(mail.bcc),
              XMailer.emil,
              Subject(mail.subject),
              TextBody[F](mail.body)
            )
          )
        }

        def sendMail(cfg: MailConfig, mail: Mail[F]): F[Either[SendResult, String]] =
          emil(cfg).send(mail).map(_.head).attempt.map(_.left.map(SendResult.SendFailure))

        (for {
          _ <- RShare
            .findCurrentActive(mail.shareId)
            .filter(_._2.cid == account.collective)
            .mapK(store.transform)
          mailCfg <- getSmtpSettings
          mail <- createMail(mailCfg)
          mid <- OptionT.liftF(sendMail(mailCfg.toMailConfig, mail))
          conv = mid.fold(identity, id => SendResult.Success(id))
        } yield conv).getOrElse(SendResult.NotFound)
      }

    }
}
