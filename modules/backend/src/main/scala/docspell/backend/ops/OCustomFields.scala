package docspell.backend.ops

import cats.data.OptionT
import cats.effect._

import docspell.backend.ops.OCustomFields.CustomFieldData
import docspell.backend.ops.OCustomFields.NewCustomField
import docspell.common._
import docspell.store.AddResult
import docspell.store.Store
import docspell.store.UpdateResult
import docspell.store.queries.QCustomField
import docspell.store.records.RCustomField
import docspell.store.records.RCustomFieldValue

import doobie._

trait OCustomFields[F[_]] {

  def findAll(coll: Ident, nameQuery: Option[String]): F[Vector[CustomFieldData]]

  def findById(coll: Ident, fieldId: Ident): F[Option[CustomFieldData]]

  def create(field: NewCustomField): F[AddResult]

  def change(field: RCustomField): F[UpdateResult]

  def delete(coll: Ident, fieldIdOrName: Ident): F[UpdateResult]
}

object OCustomFields {

  type CustomFieldData = QCustomField.CustomFieldData
  val CustomFieldData = QCustomField.CustomFieldData

  case class NewCustomField(
      name: Ident,
      label: Option[String],
      ftype: CustomFieldType,
      cid: Ident
  )

  def apply[F[_]: Effect](
      store: Store[F]
  ): Resource[F, OCustomFields[F]] =
    Resource.pure[F, OCustomFields[F]](new OCustomFields[F] {

      def findAll(coll: Ident, nameQuery: Option[String]): F[Vector[CustomFieldData]] =
        store.transact(QCustomField.findAllLike(coll, nameQuery))

      def findById(coll: Ident, field: Ident): F[Option[CustomFieldData]] =
        store.transact(QCustomField.findById(field, coll))

      def create(field: NewCustomField): F[AddResult] = {
        val exists = RCustomField.exists(field.name, field.cid)
        val insert = for {
          id  <- Ident.randomId[ConnectionIO]
          now <- Timestamp.current[ConnectionIO]
          rec = RCustomField(id, field.name, field.label, field.cid, field.ftype, now)
          n <- RCustomField.insert(rec)
        } yield n

        store.add(insert, exists)
      }

      def change(field: RCustomField): F[UpdateResult] =
        UpdateResult.fromUpdate(store.transact(RCustomField.update(field)))

      def delete(coll: Ident, fieldIdOrName: Ident): F[UpdateResult] = {
        val update =
          for {
            field <- OptionT(RCustomField.findByIdOrName(fieldIdOrName, coll))
            n     <- OptionT.liftF(RCustomFieldValue.deleteByField(field.id))
            k     <- OptionT.liftF(RCustomField.deleteById(field.id, coll))
          } yield n + k

        UpdateResult.fromUpdate(store.transact(update.getOrElse(0)))
      }
    })
}
