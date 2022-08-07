/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.jsonminiq.JsonMiniQuery
import docspell.notification.api.EventType
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

final case class RNotificationHook(
    id: Ident,
    uid: Ident,
    enabled: Boolean,
    allEvents: Boolean,
    eventFilter: Option[JsonMiniQuery],
    created: Timestamp
) {}

object RNotificationHook {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "notification_hook"

    val id = Column[Ident]("id", this)
    val uid = Column[Ident]("uid", this)
    val enabled = Column[Boolean]("enabled", this)
    val allEvents = Column[Boolean]("all_events", this)
    val eventFilter = Column[JsonMiniQuery]("event_filter", this)
    val created = Column[Timestamp]("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(
        id,
        uid,
        enabled,
        allEvents,
        eventFilter,
        created
      )
  }

  val T: Table = Table(None)
  def as(alias: String): Table = Table(Some(alias))

  def insert(r: RNotificationHook): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${r.id},${r.uid},${r.enabled},${r.allEvents},${r.eventFilter},${r.created}"
    )

  def deleteByAccount(id: Ident, userId: Ident): ConnectionIO[Int] =
    DML.delete(
      T,
      T.id === id && T.uid === userId
    )

  def update(r: RNotificationHook): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id && T.uid === r.uid,
      DML.set(
        T.enabled.setTo(r.enabled),
        T.allEvents.setTo(r.allEvents),
        T.eventFilter.setTo(r.eventFilter)
      )
    )

  def findByAccount(userId: Ident): ConnectionIO[Vector[RNotificationHook]] =
    Select(
      select(T.all),
      from(T),
      T.uid === userId
    ).build.query[RNotificationHook].to[Vector]

  def getById(id: Ident, userId: Ident): ConnectionIO[Option[RNotificationHook]] =
    Select(
      select(T.all),
      from(T),
      T.id === id && T.uid === userId
    ).build.query[RNotificationHook].option

  def findAllByAccount(
      userId: Ident
  ): ConnectionIO[Vector[(RNotificationHook, List[EventType])]] = {
    val h = RNotificationHook.as("h")
    val e = RNotificationHookEvent.as("e")

    val withEvents = Select(
      select(h.all :+ e.eventType),
      from(h).innerJoin(e, e.hookId === h.id),
      h.uid === userId
    ).orderBy(h.id)
      .build
      .query[(RNotificationHook, EventType)]
      .to[Vector]
      .map(_.groupBy(_._1).view.mapValues(_.map(_._2).toList).toVector)

    val withoutEvents =
      Select(
        select(h.all),
        from(h),
        h.id.notIn(Select(select(e.hookId), from(e))) && h.uid === userId
      ).build
        .query[RNotificationHook]
        .to[Vector]
        .map(list => list.map(h => (h, Nil: List[EventType])))

    for {
      sel1 <- withEvents
      sel2 <- withoutEvents
    } yield sel1 ++ sel2
  }
}
