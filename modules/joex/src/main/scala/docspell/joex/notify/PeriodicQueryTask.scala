/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.notify

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.ops.ONotification
import docspell.backend.ops.search.{OSearch, QueryParseResult}
import docspell.common._
import docspell.notification.api.EventContext
import docspell.notification.api.NotificationChannel
import docspell.notification.api.PeriodicQueryArgs
import docspell.query.{FulltextExtract, ItemQuery, ItemQueryParser}
import docspell.scheduler.Context
import docspell.scheduler.Task
import docspell.store.Store
import docspell.store.qb.Batch
import docspell.store.queries.ListItem
import docspell.store.records.RQueryBookmark
import docspell.store.records.RShare

object PeriodicQueryTask {
  val taskName = PeriodicQueryArgs.taskName

  type Args = PeriodicQueryArgs

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn(s"Cancelling ${taskName.id} task"))

  def apply[F[_]: Sync](
      store: Store[F],
      search: OSearch[F],
      notificationOps: ONotification[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      val limit = 7
      Timestamp.current[F].flatMap { now =>
        withItems(ctx, store, search, limit, now) { items =>
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
    TaskOperations.withChannel(
      ctx.logger,
      ctx.args.channels,
      ctx.args.account.userId,
      ops
    )(cont)

  private def queryString(q: ItemQuery.Expr) =
    ItemQueryParser.asString(q)

  def withQuery[F[_]: Sync](ctx: Context[F, Args], store: Store[F], search: OSearch[F])(
      cont: QueryParseResult.Success => F[Unit]
  ): F[Unit] = {
    def fromBookmark(id: String) =
      store
        .transact(
          RQueryBookmark
            .findByNameOrId(ctx.args.account.collectiveId, ctx.args.account.userId, id)
        )
        .map(_.map(_.query))
        .flatTap(q =>
          ctx.logger.debug(s"Loaded bookmark '$id': ${q.map(_.expr).map(queryString)}")
        )

    def fromShare(id: String) =
      store
        .transact(
          RShare.findOneByCollective(ctx.args.account.collectiveId, Some(true), id)
        )
        .map(_.map(_.query))
        .flatTap(q =>
          ctx.logger.debug(s"Loaded share '$id': ${q.map(_.expr).map(queryString)}")
        )

    def fromBookmarkOrShare(id: String) =
      OptionT(fromBookmark(id)).orElse(OptionT(fromShare(id))).value

    def runQuery(bm: Option[ItemQuery], str: Option[String]): F[Unit] = {
      val bmFtsQuery = bm.map(e => FulltextExtract.findFulltext(e.expr))
      val queryStrResult =
        str.map(search.parseQueryString(ctx.args.account, SearchMode.Normal, _))

      (bmFtsQuery, queryStrResult) match {
        case (
              Some(bmr: FulltextExtract.SuccessResult),
              Some(QueryParseResult.Success(q, ftq))
            ) =>
          val nq = bmr.getExprPart.map(q.andCond).getOrElse(q)
          val nftq =
            (bmr.getFulltextPart |+| Some(" ") |+| ftq).map(_.trim).filter(_.nonEmpty)
          val r = QueryParseResult.Success(nq, nftq)
          ctx.logger.debug(s"Running query: $r") *> cont(r)

        case (None, Some(r: QueryParseResult.Success)) =>
          ctx.logger.debug(s"Running query: $r") *> cont(r)

        case (Some(bmr: FulltextExtract.SuccessResult), None) =>
          search.parseQueryString(ctx.args.account, SearchMode.Normal, "") match {
            case QueryParseResult.Success(q, _) =>
              val nq = bmr.getExprPart.map(q.andCond).getOrElse(q)
              ctx.logger.debug(s"Running query: $nq") *>
                cont(QueryParseResult.Success(nq, bmr.getFulltextPart))

            case err =>
              ctx.logger.error(s"Internal error: $err")
          }

        case (failure1, res2) =>
          ctx.logger.error(s"One or more error reading queries: $failure1 and $res2")
      }
    }

    (ctx.args.bookmark, ctx.args.query) match {
      case (Some(bm), Some(qstr)) =>
        ctx.logger.debug(s"Using bookmark $bm and query $qstr") *>
          fromBookmarkOrShare(bm).flatMap(bq => runQuery(bq, qstr.query.some))

      case (Some(bm), None) =>
        fromBookmarkOrShare(bm).flatMap {
          case Some(bq) =>
            ctx.logger.debug(s"Using bookmark: ${queryString(bq.expr)}") *>
              runQuery(bq.some, None)

          case None =>
            ctx.logger.error(
              s"No bookmark found for id: $bm. Can't continue. Please fix the task query."
            )
        }

      case (None, Some(qstr)) =>
        ctx.logger.debug(s"Using query: ${qstr.query}") *> runQuery(None, qstr.query.some)

      case (None, None) =>
        ctx.logger.error(s"No query provided for task $taskName!")
    }
  }

  def withItems[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F],
      search: OSearch[F],
      limit: Int,
      now: Timestamp
  )(
      cont: Vector[ListItem] => F[Unit]
  ): F[Unit] =
    withQuery(ctx, store, search) { qs =>
      val items = search.search(0, now.toUtcDate.some, Batch.limit(limit))(qs.q, qs.ftq)
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
      ctx.args.contentStart,
      limit,
      now
    )(cont)

}
