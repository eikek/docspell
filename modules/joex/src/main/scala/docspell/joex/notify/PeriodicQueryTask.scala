/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.notify

import cats.effect._
import cats.implicits._

import docspell.backend.ops.ONotification
import docspell.common._
import docspell.joex.scheduler.Context
import docspell.joex.scheduler.Task
import docspell.notification.api.EventContext
import docspell.notification.api.NotificationChannel
import docspell.notification.api.PeriodicQueryArgs
import docspell.query.ItemQueryParser
import docspell.store.qb.Batch
import docspell.store.queries.ListItem
import docspell.store.queries.{QItem, Query}

object PeriodicQueryTask {
  val taskName = PeriodicQueryArgs.taskName

  type Args = PeriodicQueryArgs

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn(s"Cancelling ${taskName.id} task"))

  def apply[F[_]: Sync](notificationOps: ONotification[F]): Task[F, Args, Unit] =
    Task { ctx =>
      val limit = 7
      Timestamp.current[F].flatMap { now =>
        withItems(ctx, limit, now) { items =>
          withEventContext(ctx, items, limit, now) { eventCtx =>
            withChannel(ctx, notificationOps) { channels =>
              notificationOps.sendMessage(ctx.logger, eventCtx, channels)
            }
          }
        }
      }
    }

  def withChannel[F[_]: Sync](ctx: Context[F, Args], ops: ONotification[F])(
      cont: Vector[NotificationChannel] => F[Unit]
  ): F[Unit] =
    TaskOperations.withChannel(ctx.logger, ctx.args.channel, ops)(cont)

  def withItems[F[_]: Sync](ctx: Context[F, Args], limit: Int, now: Timestamp)(
      cont: Vector[ListItem] => F[Unit]
  ): F[Unit] =
    ItemQueryParser.parse(ctx.args.query.query) match {
      case Right(q) =>
        val query = Query(Query.Fix(ctx.args.account, Some(q.expr), None))
        val items = ctx.store
          .transact(QItem.findItems(query, now.toUtcDate, 0, Batch.limit(limit)))
          .compile
          .to(Vector)

        items.flatMap(cont)
      case Left(err) =>
        ctx.logger.error(
          s"Item query is invalid, stopping: ${ctx.args.query} - ${err.render}"
        )
    }

  def withEventContext[F[_]](
      ctx: Context[F, Args],
      items: Vector[ListItem],
      limit: Int,
      now: Timestamp
  )(cont: EventContext => F[Unit]): F[Unit] =
    TaskOperations.withEventContext(
      ctx.logger,
      ctx.args.account,
      ctx.args.baseUrl,
      items,
      limit,
      now
    )(cont)

}
