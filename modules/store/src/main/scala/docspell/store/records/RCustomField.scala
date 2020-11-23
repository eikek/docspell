package docspell.store.records

import cats.implicits._

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RCustomField(
    id: Ident,
    name: Ident,
    label: Option[String],
    cid: Ident,
    ftype: CustomFieldType,
    created: Timestamp
)

object RCustomField {

  val table = fr"custom_field"

  object Columns {

    val id      = Column("id")
    val name    = Column("name")
    val label   = Column("label")
    val cid     = Column("cid")
    val ftype   = Column("ftype")
    val created = Column("created")

    val all = List(id, name, label, cid, ftype, created)
  }
  import Columns._

  def insert(value: RCustomField): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      Columns.all,
      fr"${value.id},${value.name},${value.label},${value.cid},${value.ftype},${value.created}"
    )
    sql.update.run
  }

  def exists(fname: Ident, coll: Ident): ConnectionIO[Boolean] =
    selectCount(id, table, and(name.is(fname), cid.is(coll))).query[Int].unique.map(_ > 0)

  def findById(fid: Ident, coll: Ident): ConnectionIO[Option[RCustomField]] =
    selectSimple(all, table, and(id.is(fid), cid.is(coll))).query[RCustomField].option

  def findByIdOrName(idOrName: Ident, coll: Ident): ConnectionIO[Option[RCustomField]] =
    selectSimple(all, table, and(cid.is(coll), or(id.is(idOrName), name.is(idOrName))))
      .query[RCustomField]
      .option

  def deleteById(fid: Ident, coll: Ident): ConnectionIO[Int] =
    deleteFrom(table, and(id.is(fid), cid.is(coll))).update.run

  def findAll(coll: Ident): ConnectionIO[Vector[RCustomField]] =
    selectSimple(all, table, cid.is(coll)).query[RCustomField].to[Vector]

  def update(value: RCustomField): ConnectionIO[Int] =
    updateRow(
      table,
      and(id.is(value.id), cid.is(value.cid)),
      commas(
        name.setTo(value.name),
        label.setTo(value.label),
        ftype.setTo(value.ftype)
      )
    ).update.run

  def setValue(f: RCustomField, item: Ident, fval: String): ConnectionIO[Int] =
    for {
      n <- RCustomFieldValue.updateValue(f.id, item, fval)
      k <-
        if (n == 0)
          Ident
            .randomId[ConnectionIO]
            .flatMap(nId =>
              RCustomFieldValue
                .insert(RCustomFieldValue(nId, item, f.id, fval))
            )
        else 0.pure[ConnectionIO]
    } yield n + k

}
