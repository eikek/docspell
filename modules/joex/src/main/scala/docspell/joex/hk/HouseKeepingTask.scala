package docspell.joex.hk

import cats.implicits._
import cats.effect._
import com.github.eikek.calev._

import docspell.common._
import docspell.joex.Config
import docspell.joex.scheduler.Task
import docspell.store.records._

object HouseKeepingTask {
  private val periodicId = Ident.unsafe("docspell-houskeeping")
  val systemGroup: Ident = Ident.unsafe("docspell-system")

  val taskName: Ident = Ident.unsafe("housekeeping")

  def apply[F[_]: Sync](cfg: Config): Task[F, Unit, Unit] =
    Task
      .log[F, Unit](_.info(s"Running house-keeping task now"))
      .flatMap(_ => CleanupInvitesTask(cfg.houseKeeping.cleanupInvites))
      .flatMap(_ => CleanupJobsTask(cfg.houseKeeping.cleanupJobs))

  def onCancel[F[_]: Sync]: Task[F, Unit, Unit] =
    Task.log[F, Unit](_.warn("Cancelling house-keeping task"))

  def periodicTask[F[_]: Sync](ce: CalEvent): F[RPeriodicTask] =
    RPeriodicTask
      .createJson(
        true,
        taskName,
        systemGroup,
        (),
        "Docspell house-keeping",
        systemGroup,
        Priority.Low,
        ce
      )
      .map(_.copy(id = periodicId))
}
