package docspell.backend.ops

import cats.effect._
import cats.implicits._
import cats.data.OptionT
import docspell.common._
import docspell.store._
import docspell.store.records.RUserEmail

trait OMail[F[_]] {

  def getSettings(accId: AccountId, nameQ: Option[String]): F[Vector[RUserEmail]]

  def createSettings(data: F[RUserEmail]): F[AddResult]

  def updateSettings(accId: AccountId, name: Ident, data: RUserEmail): F[Int]
}

object OMail {

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OMail[F]] =
    Resource.pure(new OMail[F] {
      def getSettings(accId: AccountId, nameQ: Option[String]): F[Vector[RUserEmail]] =
        store.transact(RUserEmail.findByAccount(accId, nameQ))

      def createSettings(data: F[RUserEmail]): F[AddResult] =
        for {
          ru <- data
          ins = RUserEmail.insert(ru)
          exists = RUserEmail.exists(ru.uid, ru.name)
          ar <- store.add(ins, exists)
        } yield ar

      def updateSettings(accId: AccountId, name: Ident, data: RUserEmail): F[Int] = {
        val op = for {
          um <- OptionT(RUserEmail.getByName(accId, name))
          n  <- OptionT.liftF(RUserEmail.update(um.id, data))
        } yield n

        store.transact(op.value).map(_.getOrElse(0))
      }
    })
}
