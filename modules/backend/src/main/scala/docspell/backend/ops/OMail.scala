package docspell.backend.ops

import cats.effect._
import cats.implicits._
import cats.data.OptionT
import emil.{MailAddress, SSLType}

import docspell.common._
import docspell.store._
import docspell.store.records.RUserEmail

trait OMail[F[_]] {

  def getSettings(accId: AccountId, nameQ: Option[String]): F[Vector[RUserEmail]]

  def findSettings(accId: AccountId, name: Ident): OptionT[F, RUserEmail]

  def createSettings(accId: AccountId, data: OMail.SmtpSettings): F[AddResult]

  def updateSettings(accId: AccountId, name: Ident, data: OMail.SmtpSettings): F[Int]

  def deleteSettings(accId: AccountId, name: Ident): F[Int]
}

object OMail {

  case class SmtpSettings(
      name: Ident,
      smtpHost: String,
      smtpPort: Option[Int],
      smtpUser: Option[String],
      smtpPassword: Option[Password],
      smtpSsl: SSLType,
      smtpCertCheck: Boolean,
      mailFrom: MailAddress,
      mailReplyTo: Option[MailAddress]
  ) {

    def toRecord(accId: AccountId) =
      RUserEmail.fromAccount(
        accId,
        name,
        smtpHost,
        smtpPort,
        smtpUser,
        smtpPassword,
        smtpSsl,
        smtpCertCheck,
        mailFrom,
        mailReplyTo
      )
  }

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OMail[F]] =
    Resource.pure(new OMail[F] {
      def getSettings(accId: AccountId, nameQ: Option[String]): F[Vector[RUserEmail]] =
        store.transact(RUserEmail.findByAccount(accId, nameQ))

      def findSettings(accId: AccountId, name: Ident): OptionT[F, RUserEmail] =
        OptionT(store.transact(RUserEmail.getByName(accId, name)))

      def createSettings(accId: AccountId, s: SmtpSettings): F[AddResult] =
        (for {
          ru <- OptionT(store.transact(s.toRecord(accId).value))
          ins    = RUserEmail.insert(ru)
          exists = RUserEmail.exists(ru.uid, ru.name)
          res <- OptionT.liftF(store.add(ins, exists))
        } yield res).getOrElse(AddResult.Failure(new Exception("User not found")))

      def updateSettings(accId: AccountId, name: Ident, data: SmtpSettings): F[Int] = {
        val op = for {
          um <- OptionT(RUserEmail.getByName(accId, name))
          ru <- data.toRecord(accId)
          n  <- OptionT.liftF(RUserEmail.update(um.id, ru))
        } yield n

        store.transact(op.value).map(_.getOrElse(0))
      }

      def deleteSettings(accId: AccountId, name: Ident): F[Int] =
        store.transact(RUserEmail.delete(accId, name))
    })
}
