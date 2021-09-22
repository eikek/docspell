/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RJobGroupUse(groupId: Ident, workerId: Ident) {}

object RJobGroupUse {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "jobgroupuse"

    val group = Column[Ident]("groupid", this)
    val worker = Column[Ident]("workerid", this)
    val all = NonEmptyList.of[Column[_]](group, worker)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RJobGroupUse): ConnectionIO[Int] =
    DML.insert(T, T.all, fr"${v.groupId},${v.workerId}")

  def updateGroup(v: RJobGroupUse): ConnectionIO[Int] =
    DML.update(T, T.worker === v.workerId, DML.set(T.group.setTo(v.groupId)))

  def setGroup(v: RJobGroupUse): ConnectionIO[Int] =
    updateGroup(v).flatMap(n => if (n > 0) n.pure[ConnectionIO] else insert(v))

  def findGroup(workerId: Ident): ConnectionIO[Option[Ident]] =
    run(select(T.group), from(T), T.worker === workerId).query[Ident].option

  def deleteAll: ConnectionIO[Int] =
    DML.delete(T, T.group.isNotNull)
}
