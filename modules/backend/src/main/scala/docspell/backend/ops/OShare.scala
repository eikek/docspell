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
import docspell.backend.ops.OShare.{ShareQuery, VerifyResult}
import docspell.backend.ops.OSimpleSearch.StringSearchResult
import docspell.common._
import docspell.query.ItemQuery
import docspell.query.ItemQuery.Expr
import docspell.query.ItemQuery.Expr.AttachId
import docspell.store.Store
import docspell.store.queries.SearchSummary
import docspell.store.records.RShare

import scodec.bits.ByteVector

trait OShare[F[_]] {

  def findAll(collective: Ident): F[List[RShare]]

  def delete(id: Ident, collective: Ident): F[Boolean]

  def addNew(share: OShare.NewShare): F[OShare.ChangeResult]

  def findOne(id: Ident, collective: Ident): OptionT[F, RShare]

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
}

object OShare {
  final case class ShareQuery(id: Ident, cid: Ident, query: ItemQuery) {

    //TODO
    def asAccount: AccountId =
      AccountId(cid, Ident.unsafe(""))
  }

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
      cid: Ident,
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

    def success(id: Ident): ChangeResult = Success(id)
    def publishUntilInPast: ChangeResult = PublishUntilInPast
  }

  def apply[F[_]: Async](
      store: Store[F],
      itemSearch: OItemSearch[F],
      simpleSearch: OSimpleSearch[F]
  ): OShare[F] =
    new OShare[F] {
      private[this] val logger = Logger.log4s[F](org.log4s.getLogger)

      def findAll(collective: Ident): F[List[RShare]] =
        store.transact(RShare.findAllByCollective(collective))

      def delete(id: Ident, collective: Ident): F[Boolean] =
        store.transact(RShare.deleteByIdAndCid(id, collective)).map(_ > 0)

      def addNew(share: NewShare): F[ChangeResult] =
        for {
          curTime <- Timestamp.current[F]
          id <- Ident.randomId[F]
          pass = share.password.map(PasswordCrypt.crypt)
          record = RShare(
            id,
            share.cid,
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
            else store.transact(RShare.insert(record)).map(_ => ChangeResult.success(id))
        } yield res

      def update(
          id: Ident,
          share: OShare.NewShare,
          removePassword: Boolean
      ): F[ChangeResult] =
        for {
          curTime <- Timestamp.current[F]
          record = RShare(
            id,
            share.cid,
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
            else
              store
                .transact(RShare.updateData(record, removePassword))
                .map(_ => ChangeResult.success(id))
        } yield res

      def findOne(id: Ident, collective: Ident): OptionT[F, RShare] =
        RShare.findOne(id, collective).mapK(store.transform)

      def verify(
          key: ByteVector
      )(id: Ident, password: Option[Password]): F[VerifyResult] =
        RShare
          .findCurrentActive(id)
          .mapK(store.transform)
          .semiflatMap { share =>
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
          .map(share => ShareQuery(share.id, share.cid, share.query))

      def findAttachmentPreview(
          attachId: Ident,
          shareId: Ident
      ): OptionT[F, AttachmentPreviewData[F]] =
        for {
          sq <- findShareQuery(shareId)
          _ <- checkAttachment(sq, AttachId(attachId.id))
          res <- OptionT(itemSearch.findAttachmentPreview(attachId, sq.cid))
        } yield res

      def findAttachment(attachId: Ident, shareId: Ident): OptionT[F, AttachmentData[F]] =
        for {
          sq <- findShareQuery(shareId)
          _ <- checkAttachment(sq, AttachId(attachId.id))
          res <- OptionT(itemSearch.findAttachment(attachId, sq.cid))
        } yield res

      def findItem(itemId: Ident, shareId: Ident): OptionT[F, ItemData] =
        for {
          sq <- findShareQuery(shareId)
          _ <- checkAttachment(sq, Expr.itemIdEq(itemId.id))
          res <- OptionT(itemSearch.findItem(itemId, sq.cid))
        } yield res

      /** Check whether the attachment with the given id is in the results of the given
        * share
        */
      private def checkAttachment(sq: ShareQuery, idExpr: Expr): OptionT[F, Unit] = {
        val checkQuery = Query(
          Query.Fix(sq.asAccount, Some(sq.query.expr), None),
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
            val fix = Query.Fix(share.asAccount, Some(share.query.expr), None)
            simpleSearch
              .searchSummaryByString(settings)(fix, q)
              .map {
                case StringSearchResult.Success(summary) =>
                  StringSearchResult.Success(summary.onlyExisting)
                case other => other
              }
          }
    }
}
