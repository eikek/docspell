package docspell.joex.preview

import fs2.{Chunk, Stream}
import docspell.common._
import cats.effect._
import cats.implicits._
import docspell.store.queue.JobQueue
import docspell.backend.ops.OJoex
import docspell.joex.scheduler.Task
import docspell.joex.scheduler.Context
import docspell.store.records.RAttachment
import docspell.store.records.RJob

object AllPreviewsTask {

  type Args = AllPreviewsArgs

  def apply[F[_]: Sync](queue: JobQueue[F], joex: OJoex[F]): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info("Generating previews for attachments")
        n <- submitConversionJobs(ctx, queue)
        _ <- ctx.logger.info(s"Submitted $n jobs")
        _ <- joex.notifyAllNodes
      } yield ()
    }

  def onCancel[F[_]: Sync]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling all-previews task"))

  def submitConversionJobs[F[_]: Sync](
      ctx: Context[F, Args],
      queue: JobQueue[F]
  ): F[Int] =
    ctx.store
      .transact(RAttachment.findWithoutPreview(ctx.args.collective, 50))
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
        id  <- Ident.randomId[F]
        now <- Timestamp.current[F]
      } yield RJob.newJob(
        id,
        MakePreviewArgs.taskName,
        collectiveOrSystem,
        MakePreviewArgs(ra.id, ctx.args.storeMode),
        s"Create preview ${ra.id.id}/${ra.name.getOrElse("-")}",
        now,
        collectiveOrSystem,
        Priority.Low,
        Some(MakePreviewArgs.taskName / ra.id)
      )

    val jobs = ras.traverse(mkJob)
    Stream.evalUnChunk(jobs)
  }

  def job[F[_]: Sync](storeMode: MakePreviewArgs.StoreMode, cid: Option[Ident]): F[RJob] =
    for {
      id  <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RJob.newJob(
      id,
      AllPreviewsArgs.taskName,
      cid.getOrElse(DocspellSystem.taskGroup),
      AllPreviewsArgs(cid, storeMode),
      "Create preview images",
      now,
      DocspellSystem.taskGroup,
      Priority.Low,
      Some(DocspellSystem.allPreviewTaskTracker)
    )

}
