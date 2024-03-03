/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.emptytrash

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.backend.ops.{OItem, OItemSearch}
import docspell.common._
import docspell.scheduler._
import docspell.scheduler.usertask.UserTask
import docspell.store.records.RItem

import com.github.eikek.calev.CalEvent

object EmptyTrashTask {
  type Args = EmptyTrashArgs

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling empty-trash task"))

  private val pageSize = 20

  def userTask(args: EmptyTrashArgs, ce: CalEvent): UserTask[EmptyTrashArgs] =
    UserTask(
      args.periodicTaskId,
      EmptyTrashArgs.taskName,
      enabled = true,
      ce,
      None,
      args
    )

  def apply[F[_]: Async](
      itemOps: OItem[F],
      itemSearchOps: OItemSearch[F]
  ): Task[F, Args, Result] =
    Task { ctx =>
      for {
        now <- Timestamp.current[F]
        maxDate = now.minus(ctx.args.minAge)
        _ <- ctx.logger.info(
          s"Starting removing all soft-deleted items older than ${maxDate.asString}"
        )
        nDeleted <- deleteAll(ctx.args, maxDate, itemOps, itemSearchOps, ctx)
        _ <- ctx.logger.info(s"Finished deleting $nDeleted items")
      } yield Result(nDeleted)
    }

  private def deleteAll[F[_]: Async](
      args: Args,
      maxUpdate: Timestamp,
      itemOps: OItem[F],
      itemSearchOps: OItemSearch[F],
      ctx: Context[F, _]
  ): F[Int] =
    Stream
      .eval(itemSearchOps.findDeleted(args.collective, maxUpdate, pageSize))
      .evalMap(deleteChunk(args.collective, itemOps, ctx))
      .repeat
      .takeWhile(_ > 0)
      .compile
      .foldMonoid

  private def deleteChunk[F[_]: Async](
      collective: CollectiveId,
      itemOps: OItem[F],
      ctx: Context[F, _]
  )(chunk: Vector[RItem]): F[Int] =
    if (chunk.isEmpty) {
      0.pure[F]
    } else {
      ctx.logger.info(s"Deleting next ${chunk.size} items …") *>
        chunk.traverse(i =>
          ctx.logger.debug(s"Delete item ${i.id.id} / ${i.name} now") *>
            itemOps.deleteItem(i.id, collective)
        ) *> chunk.size.pure[F]
    }
}
