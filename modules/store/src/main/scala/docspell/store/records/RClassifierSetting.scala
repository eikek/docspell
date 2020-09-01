package docspell.store.records

import cats.implicits._

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.impl._

import com.github.eikek.calev._
import doobie._
import doobie.implicits._

case class RClassifierSetting(
    cid: Ident,
    enabled: Boolean,
    schedule: CalEvent,
    category: String,
    itemCount: Int,
    fileId: Option[Ident],
    created: Timestamp
) {}

object RClassifierSetting {

  val table = fr"classifier_setting"

  object Columns {
    val cid       = Column("cid")
    val enabled   = Column("enabled")
    val schedule  = Column("schedule")
    val category  = Column("category")
    val itemCount = Column("item_count")
    val fileId    = Column("file_id")
    val created   = Column("created")
    val all       = List(cid, enabled, schedule, category, itemCount, fileId, created)
  }
  import Columns._

  def insert(v: RClassifierSetting): ConnectionIO[Int] = {
    val sql =
      insertRow(
        table,
        all,
        fr"${v.cid},${v.enabled},${v.schedule},${v.category},${v.itemCount},${v.fileId},${v.created}"
      )
    sql.update.run
  }

  def updateAll(v: RClassifierSetting): ConnectionIO[Int] = {
    val sql = updateRow(
      table,
      cid.is(v.cid),
      commas(
        enabled.setTo(v.enabled),
        schedule.setTo(v.schedule),
        category.setTo(v.category),
        itemCount.setTo(v.itemCount),
        fileId.setTo(v.fileId)
      )
    )
    sql.update.run
  }

  def updateFile(coll: Ident, fid: Ident): ConnectionIO[Int] =
    updateRow(table, cid.is(coll), fileId.setTo(fid)).update.run

  def updateSettings(v: RClassifierSetting): ConnectionIO[Int] =
    for {
      n1 <- updateRow(
        table,
        cid.is(v.cid),
        commas(
          enabled.setTo(v.enabled),
          schedule.setTo(v.schedule),
          itemCount.setTo(v.itemCount),
          category.setTo(v.category)
        )
      ).update.run
      n2 <- if (n1 <= 0) insert(v) else 0.pure[ConnectionIO]
    } yield n1 + n2

  def findById(id: Ident): ConnectionIO[Option[RClassifierSetting]] = {
    val sql = selectSimple(all, table, cid.is(id))
    sql.query[RClassifierSetting].option
  }

  def delete(coll: Ident): ConnectionIO[Int] =
    deleteFrom(table, cid.is(coll)).update.run

  case class Classifier(
      enabled: Boolean,
      schedule: CalEvent,
      itemCount: Int,
      category: Option[String]
  ) {

    def toRecord(coll: Ident, created: Timestamp): RClassifierSetting =
      RClassifierSetting(
        coll,
        enabled,
        schedule,
        category.getOrElse(""),
        itemCount,
        None,
        created
      )
  }
  object Classifier {
    def fromRecord(r: RClassifierSetting): Classifier =
      Classifier(r.enabled, r.schedule, r.itemCount, r.category.some)
  }

}
