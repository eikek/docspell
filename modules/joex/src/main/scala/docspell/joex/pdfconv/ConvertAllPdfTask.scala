/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.pdfconv

import cats.effect._
import cats.implicits._
import fs2.{Chunk, Stream}
import docspell.common._
import docspell.scheduler._
import docspell.scheduler.usertask.UserTaskScope
import docspell.store.Store
import docspell.store.records.RAttachment

/* A task to find all non-converted pdf files (of a collective, or
 * all) and converting them using ocrmypdf by submitting a job for
 * each found file.
 */
object ConvertAllPdfTask {
  type Args = ConvertAllPdfArgs

  def apply[F[_]: Sync](
      jobStore: JobStore[F],
      store: Store[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info("Converting pdfs using ocrmypdf")
        n <- submitConversionJobs(ctx, store, jobStore)
        _ <- ctx.logger.info(s"Submitted $n file conversion jobs")
      } yield ()
    }

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling convert-old-pdf task"))

  def submitConversionJobs[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F],
      jobStore: JobStore[F]
  ): F[Int] =
    store
      .transact(RAttachment.findNonConvertedPdf(ctx.args.collective, 50))
      .chunks
      .flatMap(createJobs[F](ctx))
      .chunks
      .evalMap(jobs => jobStore.insertAllIfNew(jobs.toVector).map(_ => jobs.size))
      .evalTap(n => ctx.logger.debug(s"Submitted $n jobs …"))
      .compile
      .foldMonoid

  private def createJobs[F[_]: Sync](
      ctx: Context[F, Args]
  )(ras: Chunk[RAttachment]): Stream[F, Job[String]] = {
    val collectiveOrSystem =
      ctx.args.collective
        .map(UserTaskScope.collective)
        .getOrElse(UserTaskScope.system)

    def mkJob(ra: RAttachment): F[Job[PdfConvTask.Args]] =
      Job.createNew(
        PdfConvTask.taskName,
        collectiveOrSystem,
        PdfConvTask.Args(ra.id),
        s"Convert pdf ${ra.id.id}/${ra.name.getOrElse("-")}",
        Priority.Low,
        Some(PdfConvTask.taskName / ra.id)
      )

    val jobs = ras.traverse(mkJob)
    Stream.evalUnChunk(jobs).map(_.encode)
  }
}
