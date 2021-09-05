/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.backend.signup

import cats.effect.{Async, Resource}
import cats.implicits._
import docspell.backend.PasswordCrypt
import docspell.common._
import docspell.common.syntax.all._
import docspell.store.records.{RCollective, RInvitation, RUser}
import docspell.store.{AddResult, Store}
import doobie.free.connection.ConnectionIO
import org.log4s.getLogger

trait OSignup[F[_]] {

  def register(cfg: Config)(data: RegisterData): F[SignupResult]

  /** Creates the given account if it doesn't exist. */
  def setupExternal(cfg: Config)(data: ExternalAccount): F[SignupResult]

  def newInvite(cfg: Config)(password: Password): F[NewInviteResult]
}

object OSignup {
  private[this] val logger = getLogger

  def apply[F[_]: Async](store: Store[F]): Resource[F, OSignup[F]] =
    Resource.pure[F, OSignup[F]](new OSignup[F] {

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
            addUser(data).map(SignupResult.fromAddResult)

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
                    if (ok) addUser(data).map(SignupResult.fromAddResult)
                    else SignupResult.invalidInvitationKey.pure[F]
                  _ <-
                    if (retryInvite(res))
                      logger
                        .fdebug(
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

      def setupExternal(cfg: Config)(data: ExternalAccount): F[SignupResult] =
        cfg.mode match {
          case Config.Mode.Closed =>
            SignupResult.signupClosed.pure[F]
          case _ =>
            if (data.source == AccountSource.Local)
              SignupResult.failure(new Exception("Account source must not be LOCAL!")).pure[F]
            else for {
              recs <- makeRecords(data.collName, data.login, Password(""), data.source)
              cres <- store.add(RCollective.insert(recs._1), RCollective.existsById(data.collName))
              ures <- store.add(RUser.insert(recs._2), RUser.exists(data.login))
              res = cres match {
                case AddResult.Failure(ex) =>
                  SignupResult.failure(ex)
                case _ =>
                  ures match {
                    case AddResult.Failure(ex) =>
                      SignupResult.failure(ex)
                    case _ =>
                      SignupResult.success
                  }
              }
            } yield res
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

      private def addUser(data: RegisterData): F[AddResult] = {
        def insert(coll: RCollective, user: RUser): ConnectionIO[Int] =
          for {
            n1 <- RCollective.insert(coll)
            n2 <- RUser.insert(user)
          } yield n1 + n2

        def collectiveExists: ConnectionIO[Boolean] =
          RCollective.existsById(data.collName)

        val msg = s"The collective '${data.collName}' already exists."
        for {
          cu <- makeRecords(data.collName, data.login, data.password, AccountSource.Local)
          save <- store.add(insert(cu._1, cu._2), collectiveExists)
        } yield save.fold(identity, _.withMsg(msg), identity)
      }

      private def makeRecords(
          collName: Ident,
          login: Ident,
          password: Password,
          source: AccountSource
      ): F[(RCollective, RUser)] =
        for {
          id2 <- Ident.randomId[F]
          now <- Timestamp.current[F]
          c = RCollective.makeDefault(collName, now)
          u = RUser.makeDefault(
            id2,
            login,
            collName,
            PasswordCrypt.crypt(password),
            source,
            now
          )
        } yield (c, u)
    })
}
