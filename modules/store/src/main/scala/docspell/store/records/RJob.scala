package docspell.store.records

import cats.effect.Sync
import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._
import io.circe.Encoder

case class RJob(
    id: Ident,
    task: Ident,
    group: Ident,
    args: String,
    subject: String,
    submitted: Timestamp,
    submitter: Ident,
    priority: Priority,
    state: JobState,
    retries: Int,
    progress: Int,
    tracker: Option[Ident],
    worker: Option[Ident],
    started: Option[Timestamp],
    finished: Option[Timestamp]
) {

  def info: String =
    s"${id.id.substring(0, 9)}.../${group.id}/${task.id}/$priority"
}

object RJob {

  def newJob[A](
      id: Ident,
      task: Ident,
      group: Ident,
      args: A,
      subject: String,
      submitted: Timestamp,
      submitter: Ident,
      priority: Priority,
      tracker: Option[Ident]
  )(implicit E: Encoder[A]): RJob =
    RJob(
      id,
      task,
      group,
      E(args).noSpaces,
      subject,
      submitted,
      submitter,
      priority,
      JobState.Waiting,
      0,
      0,
      tracker,
      None,
      None,
      None
    )

  val table = fr"job"

  object Columns {
    val id            = Column("jid")
    val task          = Column("task")
    val group         = Column("group_")
    val args          = Column("args")
    val subject       = Column("subject")
    val submitted     = Column("submitted")
    val submitter     = Column("submitter")
    val priority      = Column("priority")
    val state         = Column("state")
    val retries       = Column("retries")
    val progress      = Column("progress")
    val tracker       = Column("tracker")
    val worker        = Column("worker")
    val started       = Column("started")
    val startedmillis = Column("startedmillis")
    val finished      = Column("finished")
    val all = List(
      id,
      task,
      group,
      args,
      subject,
      submitted,
      submitter,
      priority,
      state,
      retries,
      progress,
      tracker,
      worker,
      started,
      finished
    )
  }

  import Columns._

  def insert(v: RJob): ConnectionIO[Int] = {
    val smillis = v.started.map(_.toMillis)
    val sql = insertRow(
      table,
      all ++ List(startedmillis),
      fr"${v.id},${v.task},${v.group},${v.args},${v.subject},${v.submitted},${v.submitter},${v.priority},${v.state},${v.retries},${v.progress},${v.tracker},${v.worker},${v.started},${v.finished},$smillis"
    )
    sql.update.run
  }

  def findFromIds(ids: Seq[Ident]): ConnectionIO[Vector[RJob]] =
    if (ids.isEmpty) Sync[ConnectionIO].pure(Vector.empty[RJob])
    else selectSimple(all, table, id.isOneOf(ids)).query[RJob].to[Vector]

  def findByIdAndGroup(jobId: Ident, jobGroup: Ident): ConnectionIO[Option[RJob]] =
    selectSimple(all, table, and(id.is(jobId), group.is(jobGroup))).query[RJob].option

  def setRunningToWaiting(workerId: Ident): ConnectionIO[Int] = {
    val states: Seq[JobState] = List(JobState.Running, JobState.Scheduled)
    updateRow(
      table,
      and(worker.is(workerId), state.isOneOf(states)),
      state.setTo(JobState.Waiting: JobState)
    ).update.run
  }

  def incrementRetries(jobid: Ident): ConnectionIO[Int] =
    updateRow(
      table,
      and(id.is(jobid), state.is(JobState.Stuck: JobState)),
      retries.f ++ fr"=" ++ retries.f ++ fr"+ 1"
    ).update.run

  def setRunning(jobId: Ident, workerId: Ident, now: Timestamp): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(jobId),
      commas(
        state.setTo(JobState.Running: JobState),
        started.setTo(now),
        startedmillis.setTo(now.toMillis),
        worker.setTo(workerId)
      )
    ).update.run

  def setWaiting(jobId: Ident): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(jobId),
      commas(
        state.setTo(JobState.Waiting: JobState),
        started.setTo(None: Option[Timestamp]),
        startedmillis.setTo(None: Option[Long]),
        finished.setTo(None: Option[Timestamp])
      )
    ).update.run

  def setScheduled(jobId: Ident, workerId: Ident): ConnectionIO[Int] =
    for {
      _ <- incrementRetries(jobId)
      n <- updateRow(
            table,
            and(
              id.is(jobId),
              or(worker.isNull, worker.is(workerId)),
              state.isOneOf(Seq[JobState](JobState.Waiting, JobState.Stuck))
            ),
            commas(
              state.setTo(JobState.Scheduled: JobState),
              worker.setTo(workerId)
            )
          ).update.run
    } yield n

  def setSuccess(jobId: Ident, now: Timestamp): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(jobId),
      commas(
        state.setTo(JobState.Success: JobState),
        finished.setTo(now)
      )
    ).update.run

  def setStuck(jobId: Ident, now: Timestamp): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(jobId),
      commas(
        state.setTo(JobState.Stuck: JobState),
        finished.setTo(now)
      )
    ).update.run

  def setFailed(jobId: Ident, now: Timestamp): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(jobId),
      commas(
        state.setTo(JobState.Failed: JobState),
        finished.setTo(now)
      )
    ).update.run

  def setCancelled(jobId: Ident, now: Timestamp): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(jobId),
      commas(
        state.setTo(JobState.Cancelled: JobState),
        finished.setTo(now)
      )
    ).update.run

  def getRetries(jobId: Ident): ConnectionIO[Option[Int]] =
    selectSimple(List(retries), table, id.is(jobId)).query[Int].option

  def setProgress(jobId: Ident, perc: Int): ConnectionIO[Int] =
    updateRow(table, id.is(jobId), progress.setTo(perc)).update.run

  def selectWaiting: ConnectionIO[Option[RJob]] = {
    val sql = selectSimple(all, table, state.is(JobState.Waiting: JobState))
    sql.query[RJob].to[Vector].map(_.headOption)
  }

  def selectGroupInState(states: Seq[JobState]): ConnectionIO[Vector[Ident]] = {
    val sql = selectDistinct(List(group), table, state.isOneOf(states)) ++ orderBy(group.f)
    sql.query[Ident].to[Vector]
  }

  def delete(jobId: Ident): ConnectionIO[Int] =
    for {
      n0 <- RJobLog.deleteAll(jobId)
      n1 <- deleteFrom(table, id.is(jobId)).update.run
    } yield n0 + n1
}
