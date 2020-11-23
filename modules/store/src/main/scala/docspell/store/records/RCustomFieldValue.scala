package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RCustomFieldValue(
    id: Ident,
    itemId: Ident,
    field: Ident,
    value: String
)

object RCustomFieldValue {

  val table = fr"custom_field_value"

  object Columns {

    val id     = Column("id")
    val itemId = Column("item_id")
    val field  = Column("field")
    val value  = Column("field_value")

    val all = List(id, itemId, field, value)
  }

  def insert(value: RCustomFieldValue): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      Columns.all,
      fr"${value.id},${value.itemId},${value.field},${value.value}"
    )
    sql.update.run
  }

  def updateValue(
      fieldId: Ident,
      item: Ident,
      value: String
  ): ConnectionIO[Int] =
    updateRow(
      table,
      and(Columns.itemId.is(item), Columns.field.is(fieldId)),
      Columns.value.setTo(value)
    ).update.run

  def countField(fieldId: Ident): ConnectionIO[Int] =
    selectCount(Columns.id, table, Columns.field.is(fieldId)).query[Int].unique

  def deleteByField(fieldId: Ident): ConnectionIO[Int] =
    deleteFrom(table, Columns.field.is(fieldId)).update.run

  def deleteByItem(item: Ident): ConnectionIO[Int] =
    deleteFrom(table, Columns.itemId.is(item)).update.run

  def deleteValue(fieldId: Ident, items: NonEmptyList[Ident]): ConnectionIO[Int] =
    deleteFrom(
      table,
      and(Columns.field.is(fieldId), Columns.itemId.isIn(items))
    ).update.run
}
