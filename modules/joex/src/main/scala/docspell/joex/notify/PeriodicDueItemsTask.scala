/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.notify

import cats.data.NonEmptyList
import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.ops.ONotification
import docspell.common._
import docspell.joex.scheduler.Context
import docspell.joex.scheduler.Task
import docspell.notification.api.EventContext
import docspell.notification.api.NotificationChannel
import docspell.notification.api.PeriodicDueItemsArgs
import docspell.query.Date
import docspell.query.ItemQuery._
import docspell.query.ItemQueryDsl._
import docspell.store.qb.Batch
import docspell.store.queries.ListItem
import docspell.store.queries.{QItem, Query}
import docspell.store.records.RUser

object PeriodicDueItemsTask {
  val taskName = PeriodicDueItemsArgs.taskName

  type Args = PeriodicDueItemsArgs

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
    OptionT(ctx.store.transact(RUser.findIdByAccount(ctx.args.account)))
      .semiflatMap(userId =>
        TaskOperations.withChannel(ctx.logger, ctx.args.channel, userId, ops)(cont)
      )
      .getOrElse(())

  def withItems[F[_]: Sync](ctx: Context[F, Args], limit: Int, now: Timestamp)(
      cont: Vector[ListItem] => F[Unit]
  ): F[Unit] = {
    val rightDate = Date((now + Duration.days(ctx.args.remindDays.toLong)).toMillis)
    val q =
      Query
        .all(ctx.args.account)
        .withOrder(orderAsc = _.dueDate)
        .withFix(_.copy(query = Expr.ValidItemStates.some))
        .withCond(_ =>
          Query.QueryExpr(
            Attr.DueDate <= rightDate &&?
              ctx.args.daysBack.map(back =>
                Attr.DueDate >= Date((now - Duration.days(back.toLong)).toMillis)
              ) &&?
              NonEmptyList
                .fromList(ctx.args.tagsInclude)
                .map(ids => Q.tagIdsEq(ids.map(_.id))) &&?
              NonEmptyList
                .fromList(ctx.args.tagsExclude)
                .map(ids => Q.tagIdsIn(ids.map(_.id)).negate)
          )
        )

    for {
      res <-
        ctx.store
          .transact(
            QItem
              .findItems(q, now.toUtcDate, 0, Batch.limit(limit))
              .take(limit.toLong)
          )
          .compile
          .toVector
      _ <- cont(res)
    } yield ()
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
      None,
      limit,
      now
    )(cont)
}
