package docspell.joex.pagecount

import cats.effect._
import cats.implicits._
import fs2.{Chunk, Stream}

import docspell.backend.JobFactory
import docspell.backend.ops.OJoex
import docspell.common._
import docspell.joex.scheduler.Context
import docspell.joex.scheduler.Task
import docspell.store.queue.JobQueue
import docspell.store.records.RAttachment
import docspell.store.records.RJob

object AllPageCountTask {

  val taskName = Ident.unsafe("all-page-count")
  type Args = Unit

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
      .transact(findAttachments)
      .chunks
      .flatMap(createJobs[F])
      .chunks
      .evalMap(jobs => queue.insertAllIfNew(jobs.toVector).map(_ => jobs.size))
      .evalTap(n => ctx.logger.debug(s"Submitted $n jobs …"))
      .compile
      .foldMonoid

  private def findAttachments[F[_]] =
    RAttachment.findAllWithoutPageCount(50)

  private def createJobs[F[_]: Sync](ras: Chunk[RAttachment]): Stream[F, RJob] = {
    def mkJob(ra: RAttachment): F[RJob] =
      JobFactory.makePageCount(MakePageCountArgs(ra.id), None)

    val jobs = ras.traverse(mkJob)
    Stream.evalUnChunk(jobs)
  }

  def job[F[_]: Sync]: F[RJob] =
    for {
      id  <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RJob.newJob(
      id,
      AllPageCountTask.taskName,
      DocspellSystem.taskGroup,
      (),
      "Create all page-counts",
      now,
      DocspellSystem.taskGroup,
      Priority.Low,
      Some(DocspellSystem.allPageCountTaskTracker)
    )

}
