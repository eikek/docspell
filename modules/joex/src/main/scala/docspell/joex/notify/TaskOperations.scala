/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.notify

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.backend.ops.ONotification
import docspell.common._
import docspell.notification.api.ChannelRef
import docspell.notification.api.Event
import docspell.notification.api.EventContext
import docspell.notification.api.NotificationChannel
import docspell.notification.impl.context.ItemSelectionCtx
import docspell.store.queries.ListItem

trait TaskOperations {

  def withChannel[F[_]: Sync](
      logger: Logger[F],
      channelsIn: NonEmptyList[ChannelRef],
      accountId: AccountId,
      ops: ONotification[F]
  )(
      cont: Vector[NotificationChannel] => F[Unit]
  ): F[Unit] = {
    val channels =
      channelsIn.toList.toVector.flatTraverse(ops.findNotificationChannel(_, accountId))

    channels.flatMap { ch =>
      if (ch.isEmpty)
        logger.error(s"No channels found for the given data: ${channelsIn}")
      else cont(ch)
    }
  }

  def withEventContext[F[_]](
      logger: Logger[F],
      account: AccountId,
      baseUrl: Option[LenientUri],
      items: Vector[ListItem],
      contentStart: Option[String],
      limit: Int,
      now: Timestamp
  )(cont: EventContext => F[Unit]): F[Unit] =
    NonEmptyList.fromFoldable(items) match {
      case Some(nel) =>
        val more = items.size >= limit
        val eventCtx = ItemSelectionCtx(
          Event.ItemSelection(account, nel.map(_.id), more, baseUrl, contentStart),
          ItemSelectionCtx.Data
            .create(account, items, baseUrl, more, now)
        )
        cont(eventCtx)
      case None =>
        logger.info(s"The query selected no items. Notification aborted")
    }
}

object TaskOperations extends TaskOperations
