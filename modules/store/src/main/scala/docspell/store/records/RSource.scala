package docspell.store.records

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.impl._

import doobie._
import doobie.implicits._

case class RSource(
    sid: Ident,
    cid: Ident,
    abbrev: String,
    description: Option[String],
    counter: Int,
    enabled: Boolean,
    priority: Priority,
    created: Timestamp,
    folderId: Option[Ident],
    fileFilter: Option[Glob]
) {

  def fileFilterOrAll: Glob =
    fileFilter.getOrElse(Glob.all)
}

object RSource {

  val table = fr"source"

  object Columns {

    val sid         = Column("sid")
    val cid         = Column("cid")
    val abbrev      = Column("abbrev")
    val description = Column("description")
    val counter     = Column("counter")
    val enabled     = Column("enabled")
    val priority    = Column("priority")
    val created     = Column("created")
    val folder      = Column("folder_id")
    val fileFilter  = Column("file_filter")

    val all =
      List(
        sid,
        cid,
        abbrev,
        description,
        counter,
        enabled,
        priority,
        created,
        folder,
        fileFilter
      )
  }

  import Columns._

  def insert(v: RSource): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      all,
      fr"${v.sid},${v.cid},${v.abbrev},${v.description},${v.counter},${v.enabled},${v.priority},${v.created},${v.folderId},${v.fileFilter}"
    )
    sql.update.run
  }

  def updateNoCounter(v: RSource): ConnectionIO[Int] = {
    val sql = updateRow(
      table,
      and(sid.is(v.sid), cid.is(v.cid)),
      commas(
        cid.setTo(v.cid),
        abbrev.setTo(v.abbrev),
        description.setTo(v.description),
        enabled.setTo(v.enabled),
        priority.setTo(v.priority),
        folder.setTo(v.folderId),
        fileFilter.setTo(v.fileFilter)
      )
    )
    sql.update.run
  }

  def incrementCounter(source: String, coll: Ident): ConnectionIO[Int] =
    updateRow(
      table,
      and(abbrev.is(source), cid.is(coll)),
      counter.f ++ fr"=" ++ counter.f ++ fr"+ 1"
    ).update.run

  def existsById(id: Ident): ConnectionIO[Boolean] = {
    val sql = selectCount(sid, table, sid.is(id))
    sql.query[Int].unique.map(_ > 0)
  }

  def existsByAbbrev(coll: Ident, abb: String): ConnectionIO[Boolean] = {
    val sql = selectCount(sid, table, and(cid.is(coll), abbrev.is(abb)))
    sql.query[Int].unique.map(_ > 0)
  }

  def findEnabled(id: Ident): ConnectionIO[Option[RSource]] =
    findEnabledSql(id).query[RSource].option

  private[records] def findEnabledSql(id: Ident): Fragment =
    selectSimple(all, table, and(sid.is(id), enabled.is(true)))

  def findCollective(sourceId: Ident): ConnectionIO[Option[Ident]] =
    selectSimple(List(cid), table, sid.is(sourceId)).query[Ident].option

  def findAll(
      coll: Ident,
      order: Columns.type => Column
  ): ConnectionIO[Vector[RSource]] =
    findAllSql(coll, order).query[RSource].to[Vector]

  private[records] def findAllSql(coll: Ident, order: Columns.type => Column): Fragment =
    selectSimple(all, table, cid.is(coll)) ++ orderBy(order(Columns).f)

  def delete(sourceId: Ident, coll: Ident): ConnectionIO[Int] =
    deleteFrom(table, and(sid.is(sourceId), cid.is(coll))).update.run

  def removeFolder(folderId: Ident): ConnectionIO[Int] = {
    val empty: Option[Ident] = None
    updateRow(table, folder.is(folderId), folder.setTo(empty)).update.run
  }
}
