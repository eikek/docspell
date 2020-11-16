package docspell.store.records

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RCustomFieldValue(
    id: Ident,
    itemId: Ident,
    field: Ident,
    valueText: Option[String],
    valueNumeric: Option[BigDecimal]
)

object RCustomFieldValue {

  val table = fr"custom_field_value"

  object Columns {

    val id           = Column("id")
    val itemId       = Column("item_id")
    val field        = Column("field")
    val valueText    = Column("value_text")
    val valueNumeric = Column("value_numeric")

    val all = List(id, itemId, field, valueText, valueNumeric)
  }

  def insert(value: RCustomFieldValue): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      Columns.all,
      fr"${value.id},${value.itemId},${value.field},${value.valueText},${value.valueNumeric}"
    )
    sql.update.run
  }

  def countField(fieldId: Ident): ConnectionIO[Int] =
    selectCount(Columns.id, table, Columns.field.is(fieldId)).query[Int].unique

  def deleteByField(fieldId: Ident): ConnectionIO[Int] =
    deleteFrom(table, Columns.field.is(fieldId)).update.run

  def deleteByItem(item: Ident): ConnectionIO[Int] =
    deleteFrom(table, Columns.itemId.is(item)).update.run
}
