/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.signup

import cats.data.OptionT
import cats.effect.{Async, Resource}
import cats.implicits._

import docspell.backend.PasswordCrypt
import docspell.common._
import docspell.store.records.{RCollective, RInvitation, RUser}
import docspell.store.{AddResult, Store}

import doobie.free.connection.ConnectionIO

trait OSignup[F[_]] {

  def register(cfg: Config)(data: RegisterData): F[SignupResult]

  /** Creates the given account if it doesn't exist. This is independent from signup
    * configuration.
    */
  def setupExternal(data: ExternalAccount): F[SignupResult]

  def newInvite(cfg: Config)(password: Password): F[NewInviteResult]
}

object OSignup {

  def apply[F[_]: Async](store: Store[F]): Resource[F, OSignup[F]] =
    Resource.pure[F, OSignup[F]](new OSignup[F] {
      private[this] val logger = docspell.logging.getLogger[F]

      def newInvite(cfg: Config)(password: Password): F[NewInviteResult] =
        if (cfg.mode == Config.Mode.Invite)
          if (cfg.newInvitePassword.isEmpty || cfg.newInvitePassword != password)
            NewInviteResult.passwordMismatch.pure[F]
          else
            store
              .transact(RInvitation.insertNew)
              .map(ri => NewInviteResult.success(ri.id))
        else
          Async[F].pure(NewInviteResult.invitationClosed)

      def register(cfg: Config)(data: RegisterData): F[SignupResult] =
        cfg.mode match {
          case Config.Mode.Open =>
            addNewAccount(data, AccountSource.Local).map(SignupResult.fromAddResult)

          case Config.Mode.Closed =>
            SignupResult.signupClosed.pure[F]

          case Config.Mode.Invite =>
            data.invite match {
              case Some(inv) =>
                for {
                  now <- Timestamp.current[F]
                  min = now.minus(cfg.inviteTime)
                  ok <- store.transact(RInvitation.useInvite(inv, min))
                  res <-
                    if (ok)
                      addNewAccount(data, AccountSource.Local)
                        .map(SignupResult.fromAddResult)
                    else SignupResult.invalidInvitationKey.pure[F]
                  _ <-
                    if (retryInvite(res))
                      logger
                        .debug(
                          s"Adding account failed ($res). Allow retry with invite."
                        ) *> store
                        .transact(
                          RInvitation.insert(RInvitation(inv, now))
                        )
                    else 0.pure[F]
                } yield res
              case None =>
                SignupResult.invalidInvitationKey.pure[F]
            }
        }

      def setupExternal(data: ExternalAccount): F[SignupResult] =
        if (data.source == AccountSource.Local)
          SignupResult
            .failure(new Exception("Account source must not be LOCAL!"))
            .pure[F]
        else {
          val maybeInsert: ConnectionIO[Unit] =
            for {
              now <- Timestamp.current[ConnectionIO]
              cid <- OptionT(RCollective.findByName(data.collName))
                .map(_.id)
                .getOrElseF(
                  RCollective.insert(RCollective.makeDefault(data.collName, now))
                )

              uid <- Ident.randomId[ConnectionIO]
              newUser = RUser.makeDefault(
                uid,
                data.login,
                cid,
                Password(""),
                AccountSource.OpenId,
                now
              )
              _ <- OptionT(RUser.findByLogin(data.login, cid.some))
                .map(_ => 1)
                .getOrElseF(RUser.insert(newUser))
            } yield ()

          store.transact(maybeInsert).attempt.map {
            case Left(ex) =>
              SignupResult.failure(ex)
            case Right(_) =>
              SignupResult.success
          }
        }

      private def retryInvite(res: SignupResult): Boolean =
        res match {
          case SignupResult.CollectiveExists =>
            true
          case SignupResult.InvalidInvitationKey =>
            false
          case SignupResult.SignupClosed =>
            true
          case SignupResult.Failure(_) =>
            true
          case SignupResult.Success =>
            false
        }

      private def addNewAccount(
          data: RegisterData,
          accountSource: AccountSource
      ): F[AddResult] = {
        def insert: ConnectionIO[Int] =
          for {
            now <- Timestamp.current[ConnectionIO]
            cid <- RCollective.insert(RCollective.makeDefault(data.collName, now))
            uid <- Ident.randomId[ConnectionIO]
            n2 <- RUser.insert(
              RUser.makeDefault(
                uid,
                data.login,
                cid,
                if (data.password.isEmpty) data.password
                else PasswordCrypt.crypt(data.password),
                accountSource,
                now
              )
            )
          } yield n2

        def collectiveExists: ConnectionIO[Boolean] =
          RCollective.existsByName(data.collName)

        val msg = s"The collective '${data.collName}' already exists."
        for {
          exists <- store.transact(collectiveExists)
          saved <-
            if (exists) AddResult.entityExists(msg).pure[F]
            else store.transact(insert).attempt.map(AddResult.fromUpdate)
        } yield saved
      }
    })
}
