/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.emptytrash

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.backend.ops.{OItem, OItemSearch}
import docspell.common._
import docspell.joex.scheduler._
import docspell.store.records.{RItem, RPeriodicTask}
import docspell.store.usertask.{UserTask, UserTaskScope}

import com.github.eikek.calev.CalEvent

object EmptyTrashTask {
  type Args = EmptyTrashArgs

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling empty-trash task"))

  private val pageSize = 20

  def periodicTask[F[_]: Sync](collective: Ident, ce: CalEvent): F[RPeriodicTask] =
    Ident
      .randomId[F]
      .flatMap(id =>
        UserTask(
          id,
          EmptyTrashArgs.taskName,
          true,
          ce,
          None,
          EmptyTrashArgs(collective)
        ).encode.toPeriodicTask(UserTaskScope(collective))
      )

  def apply[F[_]: Async](
      itemOps: OItem[F],
      itemSearchOps: OItemSearch[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      val collId = ctx.args.collective
      for {
        _        <- ctx.logger.info(s"Starting removing all soft-deleted items")
        nDeleted <- deleteAll(collId, itemOps, itemSearchOps, ctx)
        _        <- ctx.logger.info(s"Finished deleting ${nDeleted} items")
      } yield ()
    }

  private def deleteAll[F[_]: Async](
      collective: Ident,
      itemOps: OItem[F],
      itemSearchOps: OItemSearch[F],
      ctx: Context[F, _]
  ): F[Int] =
    Stream
      .eval(itemSearchOps.findDeleted(collective, pageSize))
      .evalMap(deleteChunk(collective, itemOps, ctx))
      .repeat
      .takeWhile(_ > 0)
      .compile
      .foldMonoid

  private def deleteChunk[F[_]: Async](
      collective: Ident,
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
