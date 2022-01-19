/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.{NonEmptyList => Nel}
import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.notification.api.{ChannelRef, ChannelType}
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

final case class RNotificationHookChannel(
    id: Ident,
    hookId: Ident,
    channelMail: Option[Ident],
    channelGotify: Option[Ident],
    channelMatrix: Option[Ident],
    channelHttp: Option[Ident]
) {

  def channelId: Ident =
    channelMail
      .orElse(channelGotify)
      .orElse(channelMatrix)
      .orElse(channelHttp)
      .getOrElse(
        sys.error(s"Illegal internal state: notification hook has no channel: $this")
      )

  def channelType: ChannelType =
    channelMail
      .map(_ => ChannelType.Mail)
      .orElse(channelGotify.map(_ => ChannelType.Gotify))
      .orElse(channelMatrix.map(_ => ChannelType.Matrix))
      .orElse(channelHttp.map(_ => ChannelType.Http))
      .getOrElse(
        sys.error(s"Illegal internal state: notification hook has no channel: $this")
      )
}
object RNotificationHookChannel {
  def fromRef(id: Ident, hookId: Ident, ref: ChannelRef): RNotificationHookChannel =
    ref.channelType match {
      case ChannelType.Mail   => mail(id, hookId, ref.id)
      case ChannelType.Gotify => gotify(id, hookId, ref.id)
      case ChannelType.Matrix => matrix(id, hookId, ref.id)
      case ChannelType.Http   => http(id, hookId, ref.id)
    }

  def mail(
      id: Ident,
      hookId: Ident,
      channelMail: Ident
  ): RNotificationHookChannel =
    RNotificationHookChannel(
      id,
      hookId,
      channelMail.some,
      None,
      None,
      None
    )

  def gotify(
      id: Ident,
      hookId: Ident,
      channelGotify: Ident
  ): RNotificationHookChannel =
    RNotificationHookChannel(
      id,
      hookId,
      None,
      channelGotify.some,
      None,
      None
    )

  def matrix(
      id: Ident,
      hookId: Ident,
      channelMatrix: Ident
  ): RNotificationHookChannel =
    RNotificationHookChannel(
      id,
      hookId,
      None,
      None,
      channelMatrix.some,
      None
    )

  def http(
      id: Ident,
      hookId: Ident,
      channelHttp: Ident
  ): RNotificationHookChannel =
    RNotificationHookChannel(
      id,
      hookId,
      None,
      None,
      None,
      channelHttp.some
    )

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "notification_hook_channel"

    val id = Column[Ident]("id", this)
    val hookId = Column[Ident]("hook_id", this)
    val channelMail = Column[Ident]("channel_mail", this)
    val channelGotify = Column[Ident]("channel_gotify", this)
    val channelMatrix = Column[Ident]("channel_matrix", this)
    val channelHttp = Column[Ident]("channel_http", this)

    val all: Nel[Column[_]] =
      Nel.of(id, hookId, channelMail, channelGotify, channelMatrix, channelHttp)
  }

  def as(alias: String): Table =
    Table(Some(alias))

  val T: Table = Table(None)

  def insert(r: RNotificationHookChannel): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      sql"${r.id},${r.hookId},${r.channelMail},${r.channelGotify},${r.channelMatrix},${r.channelHttp}"
    )

  def update(r: RNotificationHookChannel): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id && T.hookId === r.hookId,
      DML.set(
        T.channelMail.setTo(r.channelMail),
        T.channelGotify.setTo(r.channelGotify),
        T.channelMatrix.setTo(r.channelMatrix),
        T.channelHttp.setTo(r.channelHttp)
      )
    )

  def deleteByHook(hookId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.hookId === hookId)

  def insertAll(rs: List[RNotificationHookChannel]): ConnectionIO[Int] =
    rs.traverse(insert).map(_.sum)

  def updateAll(hookId: Ident, channels: List[ChannelRef]): ConnectionIO[Int] =
    channels
      .traverse(ref => Ident.randomId[ConnectionIO].map(id => fromRef(id, hookId, ref)))
      .flatMap(all => deleteByHook(hookId) *> insertAll(all))

  def allOf(hookId: Ident): ConnectionIO[Vector[RNotificationHookChannel]] =
    Select(select(T.all), from(T), T.hookId === hookId).build
      .query[RNotificationHookChannel]
      .to[Vector]

  def allOfNel(hookId: Ident): ConnectionIO[Nel[RNotificationHookChannel]] =
    allOf(hookId)
      .map(Nel.fromFoldable[Vector, RNotificationHookChannel])
      .flatMap(
        _.map(_.pure[ConnectionIO]).getOrElse(
          Sync[ConnectionIO]
            .raiseError(new Exception(s"Hook '${hookId.id}' has no associated channels!"))
        )
      )

  def resolveRefs(rs: Nel[RNotificationHookChannel]): ConnectionIO[List[ChannelRef]] = {
    val cmail = RNotificationChannelMail.as("cmail")
    val cgotify = RNotificationChannelGotify.as("cgotify")
    val cmatrix = RNotificationChannelMatrix.as("cmatrix")
    val chttp = RNotificationChannelHttp.as("chttp")

    def selectRef(
        idList: List[Ident],
        idCol: Column[Ident],
        nameCol: Column[String],
        ctype: ChannelType,
        table: TableDef
    ) =
      Nel
        .fromList(idList)
        .map(ids =>
          Select(
            select(idCol.s, const(ctype.name), nameCol.s),
            from(table),
            idCol.in(ids)
          )
        )

    val mailRefs = selectRef(
      rs.toList.flatMap(_.channelMail),
      cmail.id,
      cmail.name,
      ChannelType.Mail,
      cmail
    )
    val gotifyRefs = selectRef(
      rs.toList.flatMap(_.channelGotify),
      cgotify.id,
      cgotify.name,
      ChannelType.Gotify,
      cgotify
    )
    val matrixRefs = selectRef(
      rs.toList.flatMap(_.channelMatrix),
      cmatrix.id,
      cmatrix.name,
      ChannelType.Matrix,
      cmatrix
    )
    val httpRefs = selectRef(
      rs.toList.flatMap(_.channelHttp),
      chttp.id,
      chttp.name,
      ChannelType.Http,
      chttp
    )

    val queries = List(mailRefs, gotifyRefs, matrixRefs, httpRefs).flatten
    Nel.fromList(queries) match {
      case Some(nel) => union(nel.head, nel.tail: _*).build.query[ChannelRef].to[List]
      case None      => List.empty[ChannelRef].pure[ConnectionIO]
    }
  }
}
