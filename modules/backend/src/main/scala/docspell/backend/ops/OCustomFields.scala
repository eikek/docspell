/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.EitherT
import cats.data.NonEmptyList
import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.ops.OCustomFields.CustomFieldData
import docspell.backend.ops.OCustomFields.FieldValue
import docspell.backend.ops.OCustomFields.NewCustomField
import docspell.backend.ops.OCustomFields.RemoveValue
import docspell.backend.ops.OCustomFields.SetValue
import docspell.backend.ops.OCustomFields.SetValueResult
import docspell.common._
import docspell.store.AddResult
import docspell.store.Store
import docspell.store.UpdateResult
import docspell.store.queries.QCustomField
import docspell.store.records.RCustomField
import docspell.store.records.RCustomFieldValue
import docspell.store.records.RItem

import doobie._
import org.log4s.getLogger

trait OCustomFields[F[_]] {

  /** Find all fields using an optional query on the name and label */
  def findAll(coll: Ident, nameQuery: Option[String]): F[Vector[CustomFieldData]]

  /** Find one field by its id */
  def findById(coll: Ident, fieldId: Ident): F[Option[CustomFieldData]]

  /** Create a new non-existing field. */
  def create(field: NewCustomField): F[AddResult]

  /** Change an existing field. */
  def change(field: RCustomField): F[UpdateResult]

  /** Deletes the field by name or id. */
  def delete(coll: Ident, fieldIdOrName: Ident): F[UpdateResult]

  /** Sets a value given a field an an item. Existing values are overwritten. */
  def setValue(item: Ident, value: SetValue): F[SetValueResult]

  def setValueMultiple(items: NonEmptyList[Ident], value: SetValue): F[SetValueResult]

  /** Deletes a value for a given field an item. */
  def deleteValue(in: RemoveValue): F[UpdateResult]

  /** Finds all values to the given items */
  def findAllValues(itemIds: NonEmptyList[Ident]): F[List[FieldValue]]
}

object OCustomFields {

  type CustomFieldData = QCustomField.CustomFieldData
  val CustomFieldData = QCustomField.CustomFieldData

  type FieldValue = QCustomField.FieldValue
  val FieldValue = QCustomField.FieldValue

  case class NewCustomField(
      name: Ident,
      label: Option[String],
      ftype: CustomFieldType,
      cid: Ident
  )

  case class SetValue(
      field: Ident,
      value: String,
      collective: Ident
  )

  sealed trait SetValueResult
  object SetValueResult {

    case object ItemNotFound             extends SetValueResult
    case object FieldNotFound            extends SetValueResult
    case class ValueInvalid(msg: String) extends SetValueResult
    case object Success                  extends SetValueResult

    def itemNotFound: SetValueResult              = ItemNotFound
    def fieldNotFound: SetValueResult             = FieldNotFound
    def valueInvalid(msg: String): SetValueResult = ValueInvalid(msg)
    def success: SetValueResult                   = Success
  }

  case class RemoveValue(
      field: Ident,
      item: NonEmptyList[Ident],
      collective: Ident
  )

  def apply[F[_]: Async](
      store: Store[F]
  ): Resource[F, OCustomFields[F]] =
    Resource.pure[F, OCustomFields[F]](new OCustomFields[F] {

      private[this] val logger = Logger.log4s[ConnectionIO](getLogger)

      def findAllValues(itemIds: NonEmptyList[Ident]): F[List[FieldValue]] =
        store.transact(QCustomField.findAllValues(itemIds))

      def findAll(coll: Ident, nameQuery: Option[String]): F[Vector[CustomFieldData]] =
        store.transact(
          QCustomField.findAllLike(
            coll,
            nameQuery.map(WildcardString.apply).flatMap(_.both)
          )
        )

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
            _     <- OptionT.liftF(logger.info(s"Deleting field: $field"))
            n     <- OptionT.liftF(RCustomFieldValue.deleteByField(field.id))
            k     <- OptionT.liftF(RCustomField.deleteById(field.id, coll))
          } yield n + k

        UpdateResult.fromUpdate(store.transact(update.getOrElse(0)))
      }

      def setValue(item: Ident, value: SetValue): F[SetValueResult] =
        setValueMultiple(NonEmptyList.of(item), value)

      def setValueMultiple(
          items: NonEmptyList[Ident],
          value: SetValue
      ): F[SetValueResult] =
        (for {
          field <- EitherT.fromOptionF(
            store.transact(RCustomField.findByIdOrName(value.field, value.collective)),
            SetValueResult.fieldNotFound
          )
          fval <- EitherT.fromEither[F](
            field.ftype
              .parseValue(value.value)
              .leftMap(SetValueResult.valueInvalid)
              .map(field.ftype.valueString)
          )
          _ <- EitherT(
            store
              .transact(RItem.existsByIdsAndCollective(items, value.collective))
              .map(flag => if (flag) Right(()) else Left(SetValueResult.itemNotFound))
          )
          nu <- EitherT.right[SetValueResult](
            items
              .traverse(item => store.transact(RCustomField.setValue(field, item, fval)))
              .map(_.toList.sum)
          )
        } yield nu).fold(identity, _ => SetValueResult.success)

      def deleteValue(in: RemoveValue): F[UpdateResult] = {
        val update =
          for {
            field <- OptionT(RCustomField.findByIdOrName(in.field, in.collective))
            _     <- OptionT.liftF(logger.debug(s"Field found by '${in.field}': $field"))
            n     <- OptionT.liftF(RCustomFieldValue.deleteValue(field.id, in.item))
          } yield n

        UpdateResult.fromUpdate(store.transact(update.getOrElse(0)))
      }

    })

}
