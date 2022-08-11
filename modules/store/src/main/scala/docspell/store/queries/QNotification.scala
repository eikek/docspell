/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import cats.Monad
import cats.data.OptionT
import cats.implicits._

import docspell.common._
import docspell.notification.api._
import docspell.store.qb.DSL._
import docspell.store.qb.Select
import docspell.store.records._

import doobie._

object QNotification {

  private val hook = RNotificationHook.as("nh")
  private val hevent = RNotificationHookEvent.as("ne")
  private val user = RUser.as("u")

  def findChannelsForEvent(event: Event): ConnectionIO[Vector[HookChannel]] =
    for {
      hooks <- listHooks(event.account.collectiveId, event.eventType)
      chs <- hooks.traverse(h =>
        listChannels(h.id)
          .flatMap(_.flatTraverse(hc => readHookChannel(h.uid, hc)))
          .map(c => HookChannel(h, c))
      )
    } yield chs

  // --

  final case class HookChannel(
      hook: RNotificationHook,
      channels: Vector[NotificationChannel]
  )

  def listHooks(
      collective: CollectiveId,
      eventType: EventType
  ): ConnectionIO[Vector[RNotificationHook]] =
    run(
      select(hook.all),
      from(hook).leftJoin(hevent, hevent.hookId === hook.id),
      hook.enabled === true && (hook.allEvents === true || hevent.eventType === eventType) && hook.uid
        .in(
          Select(select(user.uid), from(user), user.cid === collective)
        )
    ).query[RNotificationHook].to[Vector]

  def listChannels(hookId: Ident): ConnectionIO[Vector[RNotificationHookChannel]] =
    RNotificationHookChannel.allOf(hookId)

  def readHookChannel(
      userId: Ident,
      hook: RNotificationHookChannel
  ): ConnectionIO[Vector[NotificationChannel]] =
    for {
      c1 <- read(hook.channelMail)(RNotificationChannelMail.getById(userId))(
        ChannelMap.readMail
      )
      c2 <- read(hook.channelGotify)(RNotificationChannelGotify.getById(userId))(
        ChannelMap.readGotify
      )
      c3 <- read(hook.channelMatrix)(RNotificationChannelMatrix.getById(userId))(
        ChannelMap.readMatrix
      )
      c4 <- read(hook.channelHttp)(RNotificationChannelHttp.getById(userId))(
        ChannelMap.readHttp
      )
    } yield c1 ++ c2 ++ c3 ++ c4

  def readChannel(ch: RNotificationChannel): ConnectionIO[Vector[NotificationChannel]] =
    ch.fold(
      ChannelMap.readMail,
      ChannelMap.readGotify,
      ChannelMap.readMatrix,
      ChannelMap.readHttp
    )

  private def read[A, B](channel: Option[Ident])(
      load: Ident => ConnectionIO[Option[A]]
  )(
      m: A => ConnectionIO[Vector[B]]
  ): ConnectionIO[Vector[B]] =
    channel match {
      case Some(ch) =>
        (for {
          a <- OptionT(load(ch))
          ch <- OptionT.liftF(m(a))
        } yield ch).getOrElse(Vector.empty)
      case None =>
        Monad[ConnectionIO].pure(Vector.empty)
    }
}
