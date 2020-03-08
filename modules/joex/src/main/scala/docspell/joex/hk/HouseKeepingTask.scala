package docspell.joex.hk

import cats.implicits._
import cats.effect._
import com.github.eikek.calev._

import docspell.common._
import docspell.joex.Config
import docspell.joex.scheduler.Task
import docspell.store.queue._
import docspell.store.records._

object HouseKeepingTask {
  private val periodicId = Ident.unsafe("docspell-houskeeping")
  val systemGroup: Ident = Ident.unsafe("docspell-system")

  val taskName: Ident = Ident.unsafe("housekeeping")

  def apply[F[_]: Sync: ContextShift](cfg: Config): Task[F, Unit, Unit] =
    log[F](_.info(s"Running house-keeping task now"))
      .flatMap(_ => CleanupInvitesTask(cfg))

  def onCancel[F[_]: Sync: ContextShift]: Task[F, Unit, Unit] =
    Task(_.logger.warn("Cancelling background task"))

  def submit[F[_]: Sync](
      pstore: PeriodicTaskStore[F],
      ce: CalEvent
  ): F[Unit] = {
    val makeJob =
      RPeriodicTask.createJson(
        true,
        taskName,
        systemGroup,
        (),
        "Docspell house-keeping",
        systemGroup,
        Priority.Low,
        ce
      )

    for {
      job <- makeJob
      _   <- pstore.insert(job.copy(id = periodicId)).attempt
    } yield ()
  }

  private def log[F[_]](f: Logger[F] => F[Unit]): Task[F, Unit, Unit] =
    Task(ctx => f(ctx.logger))
}
