package docspell.store.records

import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl._
import docspell.store.impl.Implicits._

case class RSource(
  sid: Ident
    , cid: Ident
    , abbrev: String
    , description: Option[String]
    , counter: Int
    , enabled: Boolean
    , priority: Priority
    , created: Timestamp) {

}

object RSource {

  val table = fr"source"

  object Columns {

    val sid = Column("sid")
    val cid = Column("cid")
    val abbrev = Column("abbrev")
    val description = Column("description")
    val counter = Column("counter")
    val enabled = Column("enabled")
    val priority = Column("priority")
    val created = Column("created")

    val all = List(sid,cid,abbrev,description,counter,enabled,priority,created)
  }

  import Columns._

  def insert(v: RSource): ConnectionIO[Int] = {
    val sql = insertRow(table, all,
      fr"${v.sid},${v.cid},${v.abbrev},${v.description},${v.counter},${v.enabled},${v.priority},${v.created}")
    sql.update.run
  }

  def updateNoCounter(v: RSource): ConnectionIO[Int] = {
    val sql = updateRow(table, and(sid is v.sid, cid is v.cid), commas(
      cid setTo v.cid,
      abbrev setTo v.abbrev,
      description setTo v.description,
      enabled setTo v.enabled,
      priority setTo v.priority
    ))
    sql.update.run
  }

  def incrementCounter(source: String, coll: Ident): ConnectionIO[Int] =
    updateRow(table, and(abbrev is source, cid is coll), counter.f ++ fr"=" ++ counter.f ++ fr"+ 1").update.run

  def existsById(id: Ident): ConnectionIO[Boolean] = {
    val sql = selectCount(sid, table, sid is id)
    sql.query[Int].unique.map(_ > 0)
  }

  def existsByAbbrev(coll: Ident, abb: String): ConnectionIO[Boolean] = {
    val sql = selectCount(sid, table, and(cid is coll, abbrev is abb))
    sql.query[Int].unique.map(_ > 0)
  }


  def find(id: Ident): ConnectionIO[Option[RSource]] = {
    val sql = selectSimple(all, table, sid is id)
    sql.query[RSource].option
  }

  def findCollective(sourceId: Ident): ConnectionIO[Option[Ident]] =
    selectSimple(List(cid), table, sid is sourceId).query[Ident].option

  def findAll(coll: Ident, order: Columns.type => Column): ConnectionIO[Vector[RSource]] = {
    val sql = selectSimple(all, table, cid is coll) ++ orderBy(order(Columns).f)
    sql.query[RSource].to[Vector]
  }

  def delete(sourceId: Ident, coll: Ident): ConnectionIO[Int] =
    deleteFrom(table, and(sid is sourceId, cid is coll)).update.run
}
