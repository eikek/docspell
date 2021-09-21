/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import com.github.eikek.calev._
import doobie._
import doobie.implicits._

final case class REmptyTrashSetting(
    cid: Ident,
    schedule: CalEvent,
    minAge: Duration,
    created: Timestamp
)

object REmptyTrashSetting {

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "empty_trash_setting"

    val cid      = Column[Ident]("cid", this)
    val schedule = Column[CalEvent]("schedule", this)
    val minAge   = Column[Duration]("min_age", this)
    val created  = Column[Timestamp]("created", this)
    val all      = NonEmptyList.of[Column[_]](cid, schedule, minAge, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: REmptyTrashSetting): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.cid},${v.schedule},${v.minAge},${v.created}"
    )

  def update(v: REmptyTrashSetting): ConnectionIO[Int] =
    for {
      n1 <- DML.update(
        T,
        T.cid === v.cid,
        DML.set(
          T.schedule.setTo(v.schedule),
          T.minAge.setTo(v.minAge)
        )
      )
      n2 <- if (n1 <= 0) insert(v) else 0.pure[ConnectionIO]
    } yield n1 + n2

  def findById(id: Ident): ConnectionIO[Option[REmptyTrashSetting]] = {
    val sql = run(select(T.all), from(T), T.cid === id)
    sql.query[REmptyTrashSetting].option
  }

  def findForAllCollectives(
      default: EmptyTrash,
      chunkSize: Int
  ): Stream[ConnectionIO, REmptyTrashSetting] = {
    val c = RCollective.as("c")
    val e = REmptyTrashSetting.as("e")
    val sql = run(
      select(
        c.id.s,
        coalesce(e.schedule.s, const(default.schedule)).s,
        coalesce(e.minAge.s, const(default.minAge)).s,
        coalesce(e.created.s, c.created.s).s
      ),
      from(c).leftJoin(e, e.cid === c.id)
    )
    sql.query[REmptyTrashSetting].streamWithChunkSize(chunkSize)
  }

  def delete(coll: Ident): ConnectionIO[Int] =
    DML.delete(T, T.cid === coll)

  final case class EmptyTrash(schedule: CalEvent, minAge: Duration) {
    def toRecord(coll: Ident, created: Timestamp): REmptyTrashSetting =
      REmptyTrashSetting(coll, schedule, minAge, created)
  }
  object EmptyTrash {
    val default = EmptyTrash(EmptyTrashArgs.defaultSchedule, Duration.days(7))
    def fromRecord(r: REmptyTrashSetting): EmptyTrash =
      EmptyTrash(r.schedule, r.minAge)
  }
}
