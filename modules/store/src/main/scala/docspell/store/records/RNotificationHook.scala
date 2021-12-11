/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._

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
    channelMail: Option[Ident],
    channelGotify: Option[Ident],
    channelMatrix: Option[Ident],
    channelHttp: Option[Ident],
    allEvents: Boolean,
    eventFilter: Option[JsonMiniQuery],
    created: Timestamp
) {
  def channelId: Ident =
    channelMail
      .orElse(channelGotify)
      .orElse(channelMatrix)
      .orElse(channelHttp)
      .getOrElse(
        sys.error(s"Illegal internal state: notification hook has no channel: ${id.id}")
      )
}

object RNotificationHook {
  def mail(
      id: Ident,
      uid: Ident,
      enabled: Boolean,
      channelMail: Ident,
      created: Timestamp
  ): RNotificationHook =
    RNotificationHook(
      id,
      uid,
      enabled,
      channelMail.some,
      None,
      None,
      None,
      false,
      None,
      created
    )

  def gotify(
      id: Ident,
      uid: Ident,
      enabled: Boolean,
      channelGotify: Ident,
      created: Timestamp
  ): RNotificationHook =
    RNotificationHook(
      id,
      uid,
      enabled,
      None,
      channelGotify.some,
      None,
      None,
      false,
      None,
      created
    )

  def matrix(
      id: Ident,
      uid: Ident,
      enabled: Boolean,
      channelMatrix: Ident,
      created: Timestamp
  ): RNotificationHook =
    RNotificationHook(
      id,
      uid,
      enabled,
      None,
      None,
      channelMatrix.some,
      None,
      false,
      None,
      created
    )

  def http(
      id: Ident,
      uid: Ident,
      enabled: Boolean,
      channelHttp: Ident,
      created: Timestamp
  ): RNotificationHook =
    RNotificationHook(
      id,
      uid,
      enabled,
      None,
      None,
      None,
      channelHttp.some,
      false,
      None,
      created
    )

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "notification_hook"

    val id = Column[Ident]("id", this)
    val uid = Column[Ident]("uid", this)
    val enabled = Column[Boolean]("enabled", this)
    val channelMail = Column[Ident]("channel_mail", this)
    val channelGotify = Column[Ident]("channel_gotify", this)
    val channelMatrix = Column[Ident]("channel_matrix", this)
    val channelHttp = Column[Ident]("channel_http", this)
    val allEvents = Column[Boolean]("all_events", this)
    val eventFilter = Column[JsonMiniQuery]("event_filter", this)
    val created = Column[Timestamp]("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(
        id,
        uid,
        enabled,
        channelMail,
        channelGotify,
        channelMatrix,
        channelHttp,
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
      sql"${r.id},${r.uid},${r.enabled},${r.channelMail},${r.channelGotify},${r.channelMatrix},${r.channelHttp},${r.allEvents},${r.eventFilter},${r.created}"
    )

  def deleteByAccount(id: Ident, account: AccountId): ConnectionIO[Int] = {
    val u = RUser.as("u")
    DML.delete(
      T,
      T.id === id && T.uid.in(Select(select(u.uid), from(u), u.isAccount(account)))
    )
  }

  def update(r: RNotificationHook): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id && T.uid === r.uid,
      DML.set(
        T.enabled.setTo(r.enabled),
        T.channelMail.setTo(r.channelMail),
        T.channelGotify.setTo(r.channelGotify),
        T.channelMatrix.setTo(r.channelMatrix),
        T.channelHttp.setTo(r.channelHttp),
        T.allEvents.setTo(r.allEvents),
        T.eventFilter.setTo(r.eventFilter)
      )
    )

  def findByAccount(account: AccountId): ConnectionIO[Vector[RNotificationHook]] =
    Select(
      select(T.all),
      from(T),
      T.uid.in(Select(select(RUser.T.uid), from(RUser.T), RUser.T.isAccount(account)))
    ).build.query[RNotificationHook].to[Vector]

  def getById(id: Ident, userId: Ident): ConnectionIO[Option[RNotificationHook]] =
    Select(
      select(T.all),
      from(T),
      T.id === id && T.uid === userId
    ).build.query[RNotificationHook].option

  def findAllByAccount(
      account: AccountId
  ): ConnectionIO[Vector[(RNotificationHook, List[EventType])]] = {
    val h = RNotificationHook.as("h")
    val e = RNotificationHookEvent.as("e")
    val userSelect =
      Select(select(RUser.T.uid), from(RUser.T), RUser.T.isAccount(account))

    val withEvents = Select(
      select(h.all :+ e.eventType),
      from(h).innerJoin(e, e.hookId === h.id),
      h.uid.in(userSelect)
    ).orderBy(h.id)
      .build
      .query[(RNotificationHook, EventType)]
      .to[Vector]
      .map(_.groupBy(_._1).view.mapValues(_.map(_._2).toList).toVector)

    val withoutEvents =
      Select(
        select(h.all),
        from(h),
        h.id.notIn(Select(select(e.hookId), from(e))) && h.uid.in(userSelect)
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
