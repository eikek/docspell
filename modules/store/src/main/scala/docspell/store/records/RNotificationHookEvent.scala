/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.notification.api.EventType
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

final case class RNotificationHookEvent(
    id: Ident,
    hookId: Ident,
    eventType: EventType
)

object RNotificationHookEvent {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "notification_hook_event"

    val id = Column[Ident]("id", this)
    val hookId = Column[Ident]("hook_id", this)
    val eventType = Column[EventType]("event_type", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(
        id,
        hookId,
        eventType
      )
  }

  val T: Table = Table(None)
  def as(alias: String): Table = Table(Some(alias))

  def insert(r: RNotificationHookEvent): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${r.id},${r.hookId},${r.eventType}"
    )

  def insertAll(hookId: Ident, events: List[EventType]): ConnectionIO[Int] =
    events
      .traverse(et =>
        Ident
          .randomId[ConnectionIO]
          .flatMap(id => insert(RNotificationHookEvent(id, hookId, et)))
      )
      .map(_.sum)

  def updateAll(hookId: Ident, events: List[EventType]): ConnectionIO[Int] =
    deleteByHook(hookId) *> insertAll(hookId, events)

  def deleteByHook(hookId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.hookId === hookId)

  def update(r: RNotificationHookEvent): ConnectionIO[Int] =
    DML.update(T, T.id === r.id, DML.set(T.eventType.setTo(r.eventType)))
}
