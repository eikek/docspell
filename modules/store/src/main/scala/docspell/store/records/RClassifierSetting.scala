package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import com.github.eikek.calev._
import doobie._
import doobie.implicits._

case class RClassifierSetting(
    cid: Ident,
    enabled: Boolean,
    schedule: CalEvent,
    itemCount: Int,
    created: Timestamp
) {}

object RClassifierSetting {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "classifier_setting"

    val cid       = Column[Ident]("cid", this)
    val enabled   = Column[Boolean]("enabled", this)
    val schedule  = Column[CalEvent]("schedule", this)
    val itemCount = Column[Int]("item_count", this)
    val created   = Column[Timestamp]("created", this)
    val all = NonEmptyList
      .of[Column[_]](cid, enabled, schedule, itemCount, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RClassifierSetting): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.cid},${v.enabled},${v.schedule},${v.itemCount},${v.created}"
    )

  def updateAll(v: RClassifierSetting): ConnectionIO[Int] =
    DML.update(
      T,
      T.cid === v.cid,
      DML.set(
        T.enabled.setTo(v.enabled),
        T.schedule.setTo(v.schedule),
        T.itemCount.setTo(v.itemCount)
      )
    )

  def updateSettings(v: RClassifierSetting): ConnectionIO[Int] =
    for {
      n1 <- DML.update(
        T,
        T.cid === v.cid,
        DML.set(
          T.enabled.setTo(v.enabled),
          T.schedule.setTo(v.schedule),
          T.itemCount.setTo(v.itemCount)
        )
      )
      n2 <- if (n1 <= 0) insert(v) else 0.pure[ConnectionIO]
    } yield n1 + n2

  def findById(id: Ident): ConnectionIO[Option[RClassifierSetting]] = {
    val sql = run(select(T.all), from(T), T.cid === id)
    sql.query[RClassifierSetting].option
  }

  def delete(coll: Ident): ConnectionIO[Int] =
    DML.delete(T, T.cid === coll)

  case class Classifier(
      enabled: Boolean,
      schedule: CalEvent,
      itemCount: Int
  ) {

    def toRecord(coll: Ident, created: Timestamp): RClassifierSetting =
      RClassifierSetting(
        coll,
        enabled,
        schedule,
        itemCount,
        created
      )
  }
  object Classifier {
    def fromRecord(r: RClassifierSetting): Classifier =
      Classifier(r.enabled, r.schedule, r.itemCount)
  }

}
