/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.pdfconv

import cats.effect._
import cats.implicits._
import fs2.{Chunk, Stream}

import docspell.backend.ops.OJoex
import docspell.common._
import docspell.joex.scheduler.{Context, Task}
import docspell.store.queue.JobQueue
import docspell.store.records.RAttachment
import docspell.store.records._

/* A task to find all non-converted pdf files (of a collective, or
 * all) and converting them using ocrmypdf by submitting a job for
 * each found file.
 */
object ConvertAllPdfTask {
  type Args = ConvertAllPdfArgs

  def apply[F[_]: Sync](queue: JobQueue[F], joex: OJoex[F]): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info("Converting pdfs using ocrmypdf")
        n <- submitConversionJobs(ctx, queue)
        _ <- ctx.logger.info(s"Submitted $n file conversion jobs")
        _ <- joex.notifyAllNodes
      } yield ()
    }

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling convert-old-pdf task"))

  def submitConversionJobs[F[_]: Sync](
      ctx: Context[F, Args],
      queue: JobQueue[F]
  ): F[Int] =
    ctx.store
      .transact(RAttachment.findNonConvertedPdf(ctx.args.collective, 50))
      .chunks
      .flatMap(createJobs[F](ctx))
      .chunks
      .evalMap(jobs => queue.insertAllIfNew(jobs.toVector).map(_ => jobs.size))
      .evalTap(n => ctx.logger.debug(s"Submitted $n jobs …"))
      .compile
      .foldMonoid

  private def createJobs[F[_]: Sync](
      ctx: Context[F, Args]
  )(ras: Chunk[RAttachment]): Stream[F, RJob] = {
    val collectiveOrSystem = ctx.args.collective.getOrElse(DocspellSystem.taskGroup)

    def mkJob(ra: RAttachment): F[RJob] =
      for {
        id <- Ident.randomId[F]
        now <- Timestamp.current[F]
      } yield RJob.newJob(
        id,
        PdfConvTask.taskName,
        collectiveOrSystem,
        PdfConvTask.Args(ra.id),
        s"Convert pdf ${ra.id.id}/${ra.name.getOrElse("-")}",
        now,
        collectiveOrSystem,
        Priority.Low,
        Some(PdfConvTask.taskName / ra.id)
      )

    val jobs = ras.traverse(mkJob)
    Stream.evalUnChunk(jobs)
  }
}
