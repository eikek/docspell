/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.download

import java.time.format.DateTimeFormatter

import cats.effect._
import cats.syntax.all._
import fs2.{Pipe, Stream}

import docspell.backend.ops.ODownloadAll
import docspell.backend.ops.ODownloadAll.model.DownloadSummary
import docspell.backend.task.DownloadZipArgs
import docspell.common._
import docspell.common.util.Zip
import docspell.scheduler.Task
import docspell.store.Store
import docspell.store.queries.{ItemFileMeta, QItem}
import docspell.store.records.RDownloadQuery

object DownloadZipTask {
  type Args = DownloadZipArgs

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn(s"Cancelling ${DownloadZipArgs.taskName.id} task"))

  def apply[F[_]: Async](
      chunkSize: Int,
      store: Store[F],
      downloadOps: ODownloadAll[F]
  ): Task[F, Args, Result] =
    Task { ctx =>
      val req = ctx.args.req
      val query = req.toQuery(ctx.args.accountId)

      val allFiles =
        Stream
          .eval(Timestamp.current[F])
          .flatMap(now =>
            store.transact(
              QItem
                .findFilesDetailed(query, req.fileType, now.toUtcDate, req.maxFiles, 50)
            )
          )
          .through(makeEntries(store))

      val storeZipFile =
        allFiles
          .through(Zip[F](ctx.logger.some).zip(chunkSize))
          .through(
            store.fileRepo.save(
              ctx.args.accountId.collective,
              FileCategory.DownloadAll,
              MimeTypeHint.advertised("application/zip")
            )
          )

      for {
        _ <- ctx.logger.info(s"Start zipping ${req.itemQueryString}")
        summary <- downloadOps.getSummary(ctx.args.accountId, req)
        _ <- ctx.logger.debug(s"Summary: $summary")
        file <- storeZipFile.compile.lastOrError
        row <- createRow(summary, ctx.args.accountId.collective, file)
        _ <- ctx.logger.debug(s"Inserting zip file: $row")
        _ <- store.transact(RDownloadQuery.insert(row))
      } yield Result(summary.fileCount)
    }

  def makeEntries[F[_]](
      store: Store[F]
  ): Pipe[F, ItemFileMeta, (String, Stream[F, Byte])] =
    _.map { itemFile =>
      val name = itemFile.fileName.getOrElse(itemFile.name)
      val month =
        DateTimeFormatter
          .ofPattern("YYYY-MM")
          .format(itemFile.date.toUtcDate)
      val entry = itemFile.corrOrg
        .map(_.name)
        .orElse(itemFile.corrPerson.map(_.name))
        .map(_.replace('/', '_'))
        .map(folder => s"$month/$folder/$name")
        .getOrElse(s"$month/$name")

      val bytes = store.fileRepo.getBytes(itemFile.fileMeta.id)
      (entry, bytes)
    }

  def createRow[F[_]: Sync](
      summary: DownloadSummary,
      cid: Ident,
      file: FileKey
  ): F[RDownloadQuery] =
    Timestamp.current[F].map { now =>
      RDownloadQuery(summary.id, cid, file, summary.fileCount, now, None, 0)
    }
}
