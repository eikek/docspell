package docspell.joex.fts

import cats.effect._
import docspell.common._
import docspell.joex.Config
import docspell.joex.scheduler.Task
import docspell.ftsclient._
import FtsWork.syntax._

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
        Task(ctx =>
          (FtsWork.clearIndex(ctx.args.collective) ++ FtsWork.insertAll[F](
            ctx.args.collective
          )).forContext(cfg, fts).run(ctx)
        )
      )

  def onCancel[F[_]: Sync]: Task[F, Args, Unit] =
    Task.log[F, Args](_.warn("Cancelling full-text re-index task"))

}
