package docspell.joex.preview

import cats.effect._
import cats.implicits._
import fs2.{Chunk, Stream}

import docspell.backend.JobFactory
import docspell.backend.ops.OJoex
import docspell.common.MakePreviewArgs.StoreMode
import docspell.common._
import docspell.joex.scheduler.Context
import docspell.joex.scheduler.Task
import docspell.store.queue.JobQueue
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

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling all-previews task"))

  def submitConversionJobs[F[_]: Sync](
      ctx: Context[F, Args],
      queue: JobQueue[F]
  ): F[Int] =
    ctx.store
      .transact(findAttachments(ctx))
      .chunks
      .flatMap(createJobs[F](ctx))
      .chunks
      .evalMap(jobs => queue.insertAllIfNew(jobs.toVector).map(_ => jobs.size))
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
  )(ras: Chunk[RAttachment]): Stream[F, RJob] = {
    val collectiveOrSystem = {
      val cid = ctx.args.collective.getOrElse(DocspellSystem.taskGroup)
      AccountId(cid, DocspellSystem.user)
    }

    def mkJob(ra: RAttachment): F[RJob] =
      JobFactory.makePreview(
        MakePreviewArgs(ra.id, ctx.args.storeMode),
        collectiveOrSystem.some
      )

    val jobs = ras.traverse(mkJob)
    Stream.evalUnChunk(jobs)
  }

  def job[F[_]: Sync](storeMode: MakePreviewArgs.StoreMode, cid: Option[Ident]): F[RJob] =
    JobFactory.allPreviews(AllPreviewsArgs(cid, storeMode), None)

}
