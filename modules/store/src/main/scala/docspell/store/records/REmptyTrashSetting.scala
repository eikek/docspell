/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import com.github.eikek.calev._
import doobie._
import doobie.implicits._

final case class REmptyTrashSetting(
    cid: Ident,
    schedule: CalEvent,
    created: Timestamp
)

object REmptyTrashSetting {

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "empty_trash_setting"

    val cid      = Column[Ident]("cid", this)
    val schedule = Column[CalEvent]("schedule", this)
    val created  = Column[Timestamp]("created", this)
    val all      = NonEmptyList.of[Column[_]](cid, schedule, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: REmptyTrashSetting): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.cid},${v.schedule},${v.created}"
    )

  def update(v: REmptyTrashSetting): ConnectionIO[Int] =
    for {
      n1 <- DML.update(
        T,
        T.cid === v.cid,
        DML.set(
          T.schedule.setTo(v.schedule)
        )
      )
      n2 <- if (n1 <= 0) insert(v) else 0.pure[ConnectionIO]
    } yield n1 + n2

  def findById(id: Ident): ConnectionIO[Option[REmptyTrashSetting]] = {
    val sql = run(select(T.all), from(T), T.cid === id)
    sql.query[REmptyTrashSetting].option
  }

  def delete(coll: Ident): ConnectionIO[Int] =
    DML.delete(T, T.cid === coll)

}
