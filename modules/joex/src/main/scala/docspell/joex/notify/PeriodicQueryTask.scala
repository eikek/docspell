/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.notify

import cats.data.OptionT
import cats.data.{NonEmptyList => Nel}
import cats.effect._
import cats.implicits._

import docspell.backend.ops.ONotification
import docspell.common._
import docspell.joex.scheduler.Context
import docspell.joex.scheduler.Task
import docspell.notification.api.EventContext
import docspell.notification.api.NotificationChannel
import docspell.notification.api.PeriodicQueryArgs
import docspell.query.ItemQuery
import docspell.query.ItemQuery.Expr.AndExpr
import docspell.query.ItemQueryParser
import docspell.store.qb.Batch
import docspell.store.queries.ListItem
import docspell.store.queries.{QItem, Query}
import docspell.store.records.RQueryBookmark
import docspell.store.records.RShare
import docspell.store.records.RUser

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
    OptionT(ctx.store.transact(RUser.findIdByAccount(ctx.args.account)))
      .semiflatMap(userId =>
        TaskOperations.withChannel(ctx.logger, ctx.args.channel, userId, ops)(cont)
      )
      .getOrElse(())

  private def queryString(q: ItemQuery.Expr) =
    ItemQueryParser.asString(q)

  def withQuery[F[_]: Sync](ctx: Context[F, Args])(cont: Query => F[Unit]): F[Unit] = {
    def fromBookmark(id: String) =
      ctx.store
        .transact(RQueryBookmark.findByNameOrId(ctx.args.account, id))
        .map(_.map(_.query))
        .flatTap(q =>
          ctx.logger.debug(s"Loaded bookmark '$id': ${q.map(_.expr).map(queryString)}")
        )

    def fromShare(id: String) =
      ctx.store
        .transact(RShare.findOneByCollective(ctx.args.account.collective, Some(true), id))
        .map(_.map(_.query))
        .flatTap(q =>
          ctx.logger.debug(s"Loaded share '$id': ${q.map(_.expr).map(queryString)}")
        )

    def fromBookmarkOrShare(id: String) =
      OptionT(fromBookmark(id)).orElse(OptionT(fromShare(id))).value

    def runQuery(bm: Option[ItemQuery], str: String): F[Unit] =
      ItemQueryParser.parse(str) match {
        case Right(q) =>
          val expr = bm.map(b => AndExpr(Nel.of(b.expr, q.expr))).getOrElse(q.expr)
          val query = Query(Query.Fix(ctx.args.account, Some(expr), None))
          ctx.logger.debug(s"Running query: ${queryString(expr)}") *> cont(query)

        case Left(err) =>
          ctx.logger.error(
            s"Item query is invalid, stopping: ${ctx.args.query.map(_.query)} - ${err.render}"
          )
      }

    (ctx.args.bookmark, ctx.args.query) match {
      case (Some(bm), Some(qstr)) =>
        ctx.logger.debug(s"Using bookmark $bm and query $qstr") *>
          fromBookmarkOrShare(bm).flatMap(bq => runQuery(bq, qstr.query))

      case (Some(bm), None) =>
        fromBookmarkOrShare(bm).flatMap {
          case Some(bq) =>
            val query = Query(Query.Fix(ctx.args.account, Some(bq.expr), None))
            ctx.logger.debug(s"Using bookmark: ${queryString(bq.expr)}") *> cont(query)

          case None =>
            ctx.logger.error(
              s"No bookmark found for id: $bm. Can't continue. Please fix the task query."
            )
        }

      case (None, Some(qstr)) =>
        ctx.logger.debug(s"Using query: ${qstr.query}") *> runQuery(None, qstr.query)

      case (None, None) =>
        ctx.logger.error(s"No query provided for task $taskName!")
    }
  }

  def withItems[F[_]: Sync](ctx: Context[F, Args], limit: Int, now: Timestamp)(
      cont: Vector[ListItem] => F[Unit]
  ): F[Unit] =
    withQuery(ctx) { query =>
      val items = ctx.store
        .transact(QItem.findItems(query, now.toUtcDate, 0, Batch.limit(limit)))
        .compile
        .to(Vector)

      items.flatMap(cont)
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
