/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.effect._
import cats.implicits._
import docspell.common._
import docspell.scheduler.{Context, Task}
import docspell.store.Store
import docspell.store.queries.QItem
import docspell.store.records.RFileMeta
import docspell.store.records.RJob
import doobie._

object DuplicateCheck {
  type Args = ProcessItemArgs

  def apply[F[_]: Sync](store: Store[F]): Task[F, Args, Args] =
    Task { ctx =>
      if (ctx.args.meta.skipDuplicate)
        for {
          retries <- getRetryCount(ctx, store)
          res <-
            if (retries == 0)
              ctx.logger
                .debug("Checking for duplicate files") *> removeDuplicates(ctx, store)
            else ctx.args.pure[F]
        } yield res
      else ctx.logger.debug("Not checking for duplicates") *> ctx.args.pure[F]
    }

  def removeDuplicates[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F]
  ): F[ProcessItemArgs] =
    for {
      fileMetas <- findDuplicates(ctx, store)
      _ <- fileMetas.traverse(deleteDuplicate(ctx, store))
      ids = fileMetas.filter(_.exists).map(_.fm.id).toSet
    } yield ctx.args.copy(files =
      ctx.args.files.filterNot(f => ids.contains(f.fileMetaId))
    )

  private def getRetryCount[F[_]: Sync](ctx: Context[F, _], store: Store[F]): F[Int] =
    store.transact(RJob.getRetries(ctx.jobId)).map(_.getOrElse(0))

  private def deleteDuplicate[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F]
  )(fd: FileMetaDupes): F[Unit] = {
    val fname = ctx.args.files.find(_.fileMetaId == fd.fm.id).flatMap(_.name)
    if (fd.exists)
      ctx.logger
        .info(s"Deleting duplicate file $fname!") *> store.fileRepo
        .delete(fd.fm.id)
    else ().pure[F]
  }

  private def findDuplicates[F[_]](
      ctx: Context[F, Args],
      store: Store[F]
  ): F[Vector[FileMetaDupes]] =
    store.transact(for {
      fileMetas <- RFileMeta.findByIds(ctx.args.files.map(_.fileMetaId))
      dupes <- fileMetas.traverse(checkDuplicate(ctx))
    } yield dupes)

  private def checkDuplicate[F[_]](
      ctx: Context[F, Args]
  )(fm: RFileMeta): ConnectionIO[FileMetaDupes] = {
    val excludes = ctx.args.files.map(_.fileMetaId).toSet
    QItem
      .findByChecksum(fm.checksum.toHex, ctx.args.meta.collective, excludes)
      .map(v => FileMetaDupes(fm, v.nonEmpty))
  }

  case class FileMetaDupes(fm: RFileMeta, exists: Boolean)
}
