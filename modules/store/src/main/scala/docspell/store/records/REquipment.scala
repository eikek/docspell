package docspell.store.records

import doobie._, doobie.implicits._
import docspell.common._
import docspell.store.impl._
import docspell.store.impl.Implicits._

case class REquipment(eid: Ident, cid: Ident, name: String, created: Timestamp) {}

object REquipment {

  val table = fr"equipment"

  object Columns {
    val eid     = Column("eid")
    val cid     = Column("cid")
    val name    = Column("name")
    val created = Column("created")
    val all     = List(eid, cid, name, created)
  }
  import Columns._

  def insert(v: REquipment): ConnectionIO[Int] = {
    val sql = insertRow(table, all, fr"${v.eid},${v.cid},${v.name},${v.created}")
    sql.update.run
  }

  def update(v: REquipment): ConnectionIO[Int] = {
    val sql = updateRow(
      table,
      and(eid.is(v.eid), cid.is(v.cid)),
      commas(
        cid.setTo(v.cid),
        name.setTo(v.name)
      )
    )
    sql.update.run
  }

  def existsByName(coll: Ident, ename: String): ConnectionIO[Boolean] = {
    val sql = selectCount(eid, table, and(cid.is(coll), name.is(ename)))
    sql.query[Int].unique.map(_ > 0)
  }

  def findById(id: Ident): ConnectionIO[Option[REquipment]] = {
    val sql = selectSimple(all, table, eid.is(id))
    sql.query[REquipment].option
  }

  def findAll(
      coll: Ident,
      nameQ: Option[String],
      order: Columns.type => Column
  ): ConnectionIO[Vector[REquipment]] = {
    val q = Seq(cid.is(coll)) ++ (nameQ match {
      case Some(str) => Seq(name.lowerLike(s"%${str.toLowerCase}%"))
      case None      => Seq.empty
    })
    val sql = selectSimple(all, table, and(q)) ++ orderBy(order(Columns).f)
    sql.query[REquipment].to[Vector]
  }

  def findLike(coll: Ident, equipName: String): ConnectionIO[Vector[IdRef]] =
    selectSimple(List(eid, name), table, and(cid.is(coll), name.lowerLike(equipName)))
      .query[IdRef]
      .to[Vector]

  def delete(id: Ident, coll: Ident): ConnectionIO[Int] =
    deleteFrom(table, and(eid.is(id), cid.is(coll))).update.run
}
