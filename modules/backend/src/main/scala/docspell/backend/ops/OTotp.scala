/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect._
import cats.implicits._

import docspell.backend.ops.OTotp.{ConfirmResult, InitResult, OtpState}
import docspell.common._
import docspell.store.records.{RTotp, RUser}
import docspell.store.{AddResult, Store, UpdateResult}
import docspell.totp.{Key, OnetimePassword, Totp}

trait OTotp[F[_]] {

  /** Return whether TOTP is enabled for this account or not. */
  def state(accountId: AccountId): F[OtpState]

  /** Initializes TOTP by generating a secret and storing it in the database. TOTP is
    * still disabled, it must be confirmed in order to be active.
    */
  def initialize(accountId: AccountId): F[InitResult]

  /** Confirms and finishes initialization. TOTP is active after this for the given
    * account.
    */
  def confirmInit(accountId: AccountId, otp: OnetimePassword): F[ConfirmResult]

  /** Disables TOTP and removes the shared secret. If a otp is specified, it must be
    * valid.
    */
  def disable(accountId: AccountId, otp: Option[OnetimePassword]): F[UpdateResult]
}

object OTotp {
  sealed trait OtpState {
    def isEnabled: Boolean
    def isDisabled = !isEnabled
    def fold[A](fe: OtpState.Enabled => A, fd: OtpState.Disabled.type => A): A
  }
  object OtpState {
    final case class Enabled(created: Timestamp) extends OtpState {
      val isEnabled = true
      def fold[A](fe: OtpState.Enabled => A, fd: OtpState.Disabled.type => A): A =
        fe(this)
    }
    case object Disabled extends OtpState {
      val isEnabled = false
      def fold[A](fe: OtpState.Enabled => A, fd: OtpState.Disabled.type => A): A =
        fd(this)
    }
  }

  sealed trait InitResult
  object InitResult {
    final case class Success(accountId: AccountId, key: Key) extends InitResult {
      def authenticatorUrl(issuer: String): LenientUri =
        LenientUri.unsafe(
          s"otpauth://totp/$issuer:${accountId.asString}?secret=${key.data.toBase32}&issuer=$issuer"
        )
    }
    case object AlreadyExists extends InitResult
    case object NotFound extends InitResult
    final case class Failed(ex: Throwable) extends InitResult

    def success(accountId: AccountId, key: Key): InitResult =
      Success(accountId, key)

    def alreadyExists: InitResult = AlreadyExists

    def failed(ex: Throwable): InitResult = Failed(ex)
  }

  sealed trait ConfirmResult
  object ConfirmResult {
    case object Success extends ConfirmResult
    case object Failed extends ConfirmResult
  }

  def apply[F[_]: Async](store: Store[F], totp: Totp): Resource[F, OTotp[F]] =
    Resource.pure[F, OTotp[F]](new OTotp[F] {
      val log = docspell.logging.getLogger[F]

      def initialize(accountId: AccountId): F[InitResult] =
        for {
          _ <- log.info(s"Initializing TOTP for account ${accountId.asString}")
          userId <- store.transact(RUser.findIdByAccount(accountId))
          result <- userId match {
            case Some(uid) =>
              for {
                record <- RTotp.generate[F](uid, totp.settings.mac)
                un <- store.transact(RTotp.updateDisabled(record))
                an <-
                  if (un != 0)
                    AddResult.entityExists("Entity exists, but update was ok").pure[F]
                  else store.add(RTotp.insert(record), RTotp.existsByLogin(accountId))
                innerResult <-
                  if (un != 0) InitResult.success(accountId, record.secret).pure[F]
                  else
                    an match {
                      case AddResult.EntityExists(msg) =>
                        log.warn(
                          s"A totp record already exists for account '${accountId.asString}': $msg!"
                        ) *>
                          InitResult.alreadyExists.pure[F]
                      case AddResult.Failure(ex) =>
                        log.warn(
                          s"Failed to setup totp record for '${accountId.asString}': ${ex.getMessage}"
                        ) *>
                          InitResult.failed(ex).pure[F]
                      case AddResult.Success =>
                        InitResult.success(accountId, record.secret).pure[F]
                    }
              } yield innerResult
            case None =>
              log.warn(s"No user found for account: ${accountId.asString}!") *>
                InitResult.NotFound.pure[F]
          }
        } yield result

      def confirmInit(accountId: AccountId, otp: OnetimePassword): F[ConfirmResult] =
        for {
          _ <- log.info(s"Confirm TOTP setup for account ${accountId.asString}")
          key <- store.transact(RTotp.findEnabledByLogin(accountId, false))
          now <- Timestamp.current[F]
          res <- key match {
            case None =>
              ConfirmResult.Failed.pure[F]
            case Some(r) =>
              val check = totp.checkPassword(r.secret, otp, now.value)
              if (check)
                store
                  .transact(RTotp.setEnabled(accountId, true))
                  .map(_ => ConfirmResult.Success)
              else ConfirmResult.Failed.pure[F]
          }
        } yield res

      def disable(accountId: AccountId, otp: Option[OnetimePassword]): F[UpdateResult] =
        otp match {
          case Some(pw) =>
            for {
              _ <- log.info(s"Validating TOTP, because it is requested to disable it.")
              key <- store.transact(RTotp.findEnabledByLogin(accountId, true))
              now <- Timestamp.current[F]
              res <- key match {
                case None =>
                  UpdateResult.failure(new Exception("TOTP not enabled.")).pure[F]
                case Some(r) =>
                  val check = totp.checkPassword(r.secret, pw, now.value)
                  if (check)
                    UpdateResult.fromUpdate(
                      store.transact(RTotp.setEnabled(accountId, false))
                    )
                  else
                    log.info(s"TOTP code was invalid. Not disabling it.") *> UpdateResult
                      .failure(new Exception("Code invalid!"))
                      .pure[F]
              }
            } yield res
          case None =>
            UpdateResult.fromUpdate(store.transact(RTotp.setEnabled(accountId, false)))
        }

      def state(accountId: AccountId): F[OtpState] =
        for {
          record <- store.transact(RTotp.findEnabledByLogin(accountId, true))
          result = record match {
            case Some(r) =>
              OtpState.Enabled(r.created)
            case None =>
              OtpState.Disabled
          }
        } yield result
    })

}
