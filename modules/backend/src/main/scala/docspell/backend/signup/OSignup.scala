package docspell.backend.signup

import cats.implicits._
import cats.effect.{Effect, Resource}
import docspell.backend.PasswordCrypt
import docspell.backend.ops.OCollective.RegisterData
import docspell.common.syntax.all._
import docspell.common._
import docspell.store.{AddResult, Store}
import docspell.store.records.{RCollective, RInvitation, RUser}
import doobie.free.connection.ConnectionIO
import org.log4s.getLogger

trait OSignup[F[_]] {

  def register(cfg: Config)(data: RegisterData): F[SignupResult]

  def newInvite(cfg: Config)(password: Password): F[NewInviteResult]
}

object OSignup {
  private[this] val logger = getLogger

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OSignup[F]] =
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
          Effect[F].pure(NewInviteResult.invitationClosed)

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
        def toRecords: F[(RCollective, RUser)] =
          for {
            id2 <- Ident.randomId[F]
            now <- Timestamp.current[F]
            c = RCollective(data.collName, CollectiveState.Active, Language.German, now)
            u = RUser(
              id2,
              data.login,
              data.collName,
              PasswordCrypt.crypt(data.password),
              UserState.Active,
              None,
              0,
              None,
              now
            )
          } yield (c, u)

        def insert(coll: RCollective, user: RUser): ConnectionIO[Int] =
          for {
            n1 <- RCollective.insert(coll)
            n2 <- RUser.insert(user)
          } yield n1 + n2

        def collectiveExists: ConnectionIO[Boolean] =
          RCollective.existsById(data.collName)

        val msg = s"The collective '${data.collName}' already exists."
        for {
          cu   <- toRecords
          save <- store.add(insert(cu._1, cu._2), collectiveExists)
        } yield save.fold(identity, _.withMsg(msg), identity)
      }
    })
}
