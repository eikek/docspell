package docspell.store.records

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RCustomField(
    id: Ident,
    name: String,
    cid: Ident,
    ftype: CustomFieldType,
    created: Timestamp
)

object RCustomField {

  val table = fr"custom_field"

  object Columns {

    val id      = Column("id")
    val name    = Column("name")
    val cid     = Column("cid")
    val ftype   = Column("ftype")
    val created = Column("created")

    val all = List(id, name, cid, ftype, created)
  }

  def insert(value: RCustomField): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      Columns.all,
      fr"${value.id},${value.name},${value.cid},${value.ftype},${value.created}"
    )
    sql.update.run
  }

  def findAll(coll: Ident): ConnectionIO[Vector[RCustomField]] =
    selectSimple(Columns.all, table, Columns.cid.is(coll)).query[RCustomField].to[Vector]
}
