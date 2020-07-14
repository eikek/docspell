package docspell.joex.fts

import cats.effect._

import docspell.common._
import docspell.ftsclient._
import docspell.joex.Config
import docspell.joex.fts.FtsWork.syntax._
import docspell.joex.scheduler.Task

object ReIndexTask {
  type Args = ReIndexTaskArgs

  val taskName = ReIndexTaskArgs.taskName
  val tracker  = DocspellSystem.migrationTaskTracker

  def apply[F[_]: ConcurrentEffect](
      cfg: Config.FullTextSearch,
      fts: FtsClient[F]
  ): Task[F, Args, Unit] =
    Task
      .log[F, Args](_.info(s"Running full-text re-index now"))
      .flatMap(_ =>
        Task(ctx => clearData[F](ctx.args.collective).forContext(cfg, fts).run(ctx))
      )

  def onCancel[F[_]: Sync]: Task[F, Args, Unit] =
    Task.log[F, Args](_.warn("Cancelling full-text re-index task"))

  private def clearData[F[_]: ConcurrentEffect](collective: Option[Ident]): FtsWork[F] =
    FtsWork.log[F](_.info("Clearing index data")) ++
      (collective match {
        case Some(_) =>
          FtsWork
            .clearIndex(collective)
            .recoverWith(
              FtsWork.log[F](_.info("Clearing data failed. Continue re-indexing."))
            ) ++
            FtsWork.log[F](_.info("Inserting data from database")) ++
            FtsWork.insertAll[F](collective)

        case None =>
          FtsWork
            .clearIndex(None)
            .recoverWith(
              FtsWork.log[F](_.info("Clearing data failed. Continue re-indexing."))
            ) ++
            FtsWork.log[F](_.info("Running index initialize")) ++
            FtsWork.allInitializeTasks[F]
      })
}
