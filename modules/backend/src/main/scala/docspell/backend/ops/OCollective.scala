package docspell.backend.ops

import cats.implicits._
import cats.effect.{Effect, Resource}
import docspell.common._
import docspell.store.{AddResult, Store}
import docspell.store.records.{RCollective, RUser}
import OCollective._
import docspell.backend.PasswordCrypt
import docspell.store.queries.QCollective

trait OCollective[F[_]] {

  def find(name: Ident): F[Option[RCollective]]

  def updateLanguage(collective: Ident, lang: Language): F[AddResult]

  def listUser(collective: Ident): F[Vector[RUser]]

  def add(s: RUser): F[AddResult]

  def update(s: RUser): F[AddResult]

  def deleteUser(login: Ident, collective: Ident): F[AddResult]

  def insights(collective: Ident): F[InsightData]

  def changePassword(
      accountId: AccountId,
      current: Password,
      newPass: Password
  ): F[PassChangeResult]
}

object OCollective {

  type InsightData = QCollective.InsightData
  val insightData = QCollective.InsightData

  sealed trait PassChangeResult
  object PassChangeResult {
    case object UserNotFound     extends PassChangeResult
    case object PasswordMismatch extends PassChangeResult
    case object UpdateFailed     extends PassChangeResult
    case object Success          extends PassChangeResult

    def userNotFound: PassChangeResult     = UserNotFound
    def passwordMismatch: PassChangeResult = PasswordMismatch
    def success: PassChangeResult          = Success
    def updateFailed: PassChangeResult     = UpdateFailed
  }

  case class RegisterData(collName: Ident, login: Ident, password: Password, invite: Option[Ident])

  sealed trait RegisterResult {
    def toEither: Either[Throwable, Unit]
  }
  object RegisterResult {
    case object Success extends RegisterResult {
      val toEither = Right(())
    }
    case class CollectiveExists(id: Ident) extends RegisterResult {
      val toEither = Left(new Exception())
    }
    case class Error(ex: Throwable) extends RegisterResult {
      val toEither = Left(ex)
    }
  }

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OCollective[F]] =
    Resource.pure(new OCollective[F] {
      def find(name: Ident): F[Option[RCollective]] =
        store.transact(RCollective.findById(name))

      def updateLanguage(collective: Ident, lang: Language): F[AddResult] =
        store
          .transact(RCollective.updateLanguage(collective, lang))
          .attempt
          .map(AddResult.fromUpdate)

      def listUser(collective: Ident): F[Vector[RUser]] =
        store.transact(RUser.findAll(collective, _.login))

      def add(s: RUser): F[AddResult] =
        store.add(
          RUser.insert(s.copy(password = PasswordCrypt.crypt(s.password))),
          RUser.exists(s.login)
        )

      def update(s: RUser): F[AddResult] =
        store.add(RUser.update(s), RUser.exists(s.login))

      def deleteUser(login: Ident, collective: Ident): F[AddResult] =
        store.transact(RUser.delete(login, collective)).attempt.map(AddResult.fromUpdate)

      def insights(collective: Ident): F[InsightData] =
        store.transact(QCollective.getInsights(collective))

      def changePassword(
          accountId: AccountId,
          current: Password,
          newPass: Password
      ): F[PassChangeResult] = {
        val q = for {
          optUser <- RUser.findByAccount(accountId)
          check   = optUser.map(_.password).map(p => PasswordCrypt.check(current, p))
          n <- check
                .filter(identity)
                .traverse(_ => RUser.updatePassword(accountId, PasswordCrypt.crypt(newPass)))
          res = check match {
            case Some(true) =>
              if (n.getOrElse(0) > 0) PassChangeResult.success else PassChangeResult.updateFailed
            case Some(false) =>
              PassChangeResult.passwordMismatch
            case None =>
              PassChangeResult.userNotFound
          }
        } yield res

        store.transact(q)
      }
    })
}
