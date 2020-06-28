package docspell.joex.fts

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.ftsclient._
import docspell.joex.Config
import docspell.joex.scheduler.Task
import docspell.store.records.RJob

object MigrationTask {
  val taskName = Ident.unsafe("full-text-index")

  def apply[F[_]: ConcurrentEffect](
      cfg: Config.FullTextSearch,
      fts: FtsClient[F]
  ): Task[F, Unit, Unit] =
    Task
      .log[F, Unit](_.info(s"Running full-text-index migrations now"))
      .flatMap(_ =>
        Task(ctx =>
          Migration[F](cfg, fts, ctx.store, ctx.logger)
            .run(migrationTasks[F])
        )
      )

  def onCancel[F[_]: Sync]: Task[F, Unit, Unit] =
    Task.log[F, Unit](_.warn("Cancelling full-text-index task"))

  def job[F[_]: Sync]: F[RJob] =
    for {
      id  <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RJob.newJob(
      id,
      taskName,
      DocspellSystem.taskGroup,
      (),
      "Create full-text index",
      now,
      DocspellSystem.taskGroup,
      Priority.Low,
      Some(DocspellSystem.migrationTaskTracker)
    )

  private val solrEngine = Ident.unsafe("solr")
  def migrationTasks[F[_]: Effect]: List[Migration[F]] =
    List(
      Migration[F](1, solrEngine, "initialize", FtsWork.initialize[F]),
      Migration[F](2, solrEngine, "Index all from database", FtsWork.insertAll[F](None))
    )

}
