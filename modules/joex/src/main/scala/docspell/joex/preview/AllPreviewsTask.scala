/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.preview

import cats.effect._
import cats.implicits._
import fs2.{Chunk, Stream}

import docspell.backend.JobFactory
import docspell.common.MakePreviewArgs.StoreMode
import docspell.common._
import docspell.scheduler._
import docspell.scheduler.usertask.UserTaskScope
import docspell.store.Store
import docspell.store.records.RAttachment

object AllPreviewsTask {

  type Args = AllPreviewsArgs

  def apply[F[_]: Sync](
      jobStore: JobStore[F],
      store: Store[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info("Generating previews for attachments")
        n <- submitConversionJobs(ctx, store, jobStore)
        _ <- ctx.logger.info(s"Submitted $n jobs")
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
      .transact(findAttachments(ctx))
      .chunks
      .flatMap(createJobs[F](ctx))
      .chunks
      .evalMap(jobs =>
        jobStore.insertAllIfNew(jobs.map(_.encode).toVector).map(_ => jobs.size)
      )
      .evalTap(n => ctx.logger.debug(s"Submitted $n jobs …"))
      .compile
      .foldMonoid

  private def findAttachments[F[_]](ctx: Context[F, Args]) =
    ctx.args.storeMode match {
      case StoreMode.Replace =>
        RAttachment.findAll(ctx.args.collective, 50)
      case StoreMode.WhenMissing =>
        RAttachment.findWithoutPreview(ctx.args.collective, 50)
    }

  private def createJobs[F[_]: Sync](
      ctx: Context[F, Args]
  )(ras: Chunk[RAttachment]): Stream[F, Job[MakePreviewArgs]] = {
    def mkJob(ra: RAttachment): F[Job[MakePreviewArgs]] =
      JobFactory.makePreview(
        MakePreviewArgs(ra.id, ctx.args.storeMode),
        ctx.args.collective
          .map(UserTaskScope.collective)
          .getOrElse(UserTaskScope.system)
      )

    val jobs = ras.traverse(mkJob)
    Stream.evalUnChunk(jobs)
  }

  def job[F[_]: Sync](
      storeMode: MakePreviewArgs.StoreMode,
      cid: Option[CollectiveId]
  ): F[Job[String]] =
    JobFactory
      .allPreviews(AllPreviewsArgs(cid, storeMode), UserTaskScope.system)
      .map(_.encode)
}
