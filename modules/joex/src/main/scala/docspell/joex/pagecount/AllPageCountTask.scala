/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.pagecount

import cats.effect._
import cats.implicits._
import fs2.{Chunk, Stream}

import docspell.backend.JobFactory
import docspell.backend.ops.OJoex
import docspell.common._
import docspell.scheduler._
import docspell.store.Store
import docspell.store.records.RAttachment

object AllPageCountTask {

  val taskName = Ident.unsafe("all-page-count")
  type Args = Unit

  def apply[F[_]: Sync](
      store: Store[F],
      jobStore: JobStore[F],
      joex: OJoex[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info("Generating previews for attachments")
        n <- submitConversionJobs(ctx, store, jobStore)
        _ <- ctx.logger.info(s"Submitted $n jobs")
        _ <- joex.notifyAllNodes
      } yield ()
    }

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling all-previews task"))

  def submitConversionJobs[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F],
      jobStore: JobStore[F]
  ): F[Int] =
    store
      .transact(findAttachments)
      .chunks
      .flatMap(createJobs[F])
      .chunks
      .evalMap(jobs => jobStore.insertAllIfNew(jobs.toVector).map(_ => jobs.size))
      .evalTap(n => ctx.logger.debug(s"Submitted $n jobs …"))
      .compile
      .foldMonoid

  private def findAttachments[F[_]] =
    RAttachment.findAllWithoutPageCount(50)

  private def createJobs[F[_]: Sync](ras: Chunk[RAttachment]): Stream[F, Job[String]] = {
    def mkJob(ra: RAttachment): F[Job[MakePageCountArgs]] =
      JobFactory.makePageCount(MakePageCountArgs(ra.id), None)

    val jobs = ras.traverse(mkJob)
    Stream.evalUnChunk(jobs).map(_.encode)
  }

  def job[F[_]: Sync]: F[Job[String]] =
    Job
      .createNew(
        AllPageCountTask.taskName,
        DocspellSystem.taskGroup,
        (),
        "Create all page-counts",
        DocspellSystem.taskGroup,
        Priority.Low,
        Some(DocspellSystem.allPageCountTaskTracker)
      )
      .map(_.encode)

}
