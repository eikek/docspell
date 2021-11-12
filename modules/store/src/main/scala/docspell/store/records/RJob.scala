/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._
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

  def isFinalState: Boolean =
    JobState.done.toList.contains(state)

  def isInProgress: Boolean =
    JobState.inProgress.contains(state)
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

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "job"

    val id = Column[Ident]("jid", this)
    val task = Column[Ident]("task", this)
    val group = Column[Ident]("group_", this)
    val args = Column[String]("args", this)
    val subject = Column[String]("subject", this)
    val submitted = Column[Timestamp]("submitted", this)
    val submitter = Column[Ident]("submitter", this)
    val priority = Column[Priority]("priority", this)
    val state = Column[JobState]("state", this)
    val retries = Column[Int]("retries", this)
    val progress = Column[Int]("progress", this)
    val tracker = Column[Ident]("tracker", this)
    val worker = Column[Ident]("worker", this)
    val started = Column[Timestamp]("started", this)
    val startedmillis = Column[Long]("startedmillis", this)
    val finished = Column[Timestamp]("finished", this)
    val all = NonEmptyList.of[Column[_]](
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

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RJob): ConnectionIO[Int] = {
    val smillis = v.started.map(_.toMillis)
    DML.insert(
      T,
      T.all ++ List(T.startedmillis),
      fr"${v.id},${v.task},${v.group},${v.args},${v.subject},${v.submitted},${v.submitter},${v.priority},${v.state},${v.retries},${v.progress},${v.tracker},${v.worker},${v.started},${v.finished},$smillis"
    )
  }

  def findFromIds(ids: Seq[Ident]): ConnectionIO[Vector[RJob]] =
    NonEmptyList.fromList(ids.toList) match {
      case None =>
        Vector.empty[RJob].pure[ConnectionIO]
      case Some(nel) =>
        run(select(T.all), from(T), T.id.in(nel)).query[RJob].to[Vector]
    }

  def findByIdAndGroup(jobId: Ident, jobGroup: Ident): ConnectionIO[Option[RJob]] =
    run(select(T.all), from(T), T.id === jobId && T.group === jobGroup).query[RJob].option

  def findById(jobId: Ident): ConnectionIO[Option[RJob]] =
    run(select(T.all), from(T), T.id === jobId).query[RJob].option

  def findByIdAndWorker(jobId: Ident, workerId: Ident): ConnectionIO[Option[RJob]] =
    run(select(T.all), from(T), T.id === jobId && T.worker === workerId)
      .query[RJob]
      .option

  def setRunningToWaiting(workerId: Ident): ConnectionIO[Int] = {
    val states: NonEmptyList[JobState] =
      NonEmptyList.of(JobState.Running, JobState.Scheduled)
    DML.update(
      T,
      where(T.worker === workerId, T.state.in(states)),
      DML.set(T.state.setTo(JobState.waiting))
    )
  }

  def incrementRetries(jobid: Ident): ConnectionIO[Int] =
    DML
      .update(
        T,
        where(T.id === jobid, T.state === JobState.stuck),
        DML.set(T.retries.increment(1))
      )

  def setRunning(jobId: Ident, workerId: Ident, now: Timestamp): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === jobId,
      DML.set(
        T.state.setTo(JobState.running),
        T.started.setTo(now),
        T.startedmillis.setTo(now.toMillis),
        T.worker.setTo(workerId)
      )
    )

  def setWaiting(jobId: Ident): ConnectionIO[Int] =
    DML
      .update(
        T,
        T.id === jobId,
        DML.set(
          T.state.setTo(JobState.Waiting: JobState),
          T.started.setTo(None: Option[Timestamp]),
          T.startedmillis.setTo(None: Option[Long]),
          T.finished.setTo(None: Option[Timestamp])
        )
      )

  def setScheduled(jobId: Ident, workerId: Ident): ConnectionIO[Int] =
    for {
      _ <- incrementRetries(jobId)
      n <- DML.update(
        T,
        where(
          T.id === jobId,
          or(T.worker.isNull, T.worker === workerId),
          T.state.in(NonEmptyList.of(JobState.waiting, JobState.stuck))
        ),
        DML.set(
          T.state.setTo(JobState.scheduled),
          T.worker.setTo(workerId)
        )
      )
    } yield n

  def setSuccess(jobId: Ident, now: Timestamp): ConnectionIO[Int] =
    DML
      .update(
        T,
        T.id === jobId,
        DML.set(
          T.state.setTo(JobState.success),
          T.finished.setTo(now)
        )
      )

  def setStuck(jobId: Ident, now: Timestamp): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === jobId,
      DML.set(
        T.state.setTo(JobState.stuck),
        T.finished.setTo(now)
      )
    )

  def setFailed(jobId: Ident, now: Timestamp): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === jobId,
      DML.set(
        T.state.setTo(JobState.failed),
        T.finished.setTo(now)
      )
    )

  def setCancelled(jobId: Ident, now: Timestamp): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === jobId,
      DML.set(
        T.state.setTo(JobState.cancelled),
        T.finished.setTo(now)
      )
    )

  def setPriority(jobId: Ident, jobGroup: Ident, prio: Priority): ConnectionIO[Int] =
    DML.update(
      T,
      where(T.id === jobId, T.group === jobGroup, T.state === JobState.waiting),
      DML.set(T.priority.setTo(prio))
    )

  def getRetries(jobId: Ident): ConnectionIO[Option[Int]] =
    run(select(T.retries), from(T), T.id === jobId).query[Int].option

  def setProgress(jobId: Ident, perc: Int): ConnectionIO[Int] =
    DML.update(T, T.id === jobId, DML.set(T.progress.setTo(perc)))

  def selectWaiting: ConnectionIO[Option[RJob]] = {
    val sql = run(select(T.all), from(T), T.state === JobState.waiting)
    sql.query[RJob].to[Vector].map(_.headOption)
  }

  def selectGroupInState(states: NonEmptyList[JobState]): ConnectionIO[Vector[Ident]] = {
    val sql =
      Select(select(T.group), from(T), T.state.in(states)).orderBy(T.group)
    sql.build.query[Ident].to[Vector]
  }

  def delete(jobId: Ident): ConnectionIO[Int] =
    for {
      n0 <- RJobLog.deleteAll(jobId)
      n1 <- DML.delete(T, T.id === jobId)
    } yield n0 + n1

  def findIdsDoneAndOlderThan(ts: Timestamp): Stream[ConnectionIO, Ident] =
    run(
      select(T.id),
      from(T),
      T.state.in(JobState.done) && (T.finished.isNull || T.finished < ts)
    ).query[Ident].stream

  def deleteDoneAndOlderThan(ts: Timestamp, batch: Int): ConnectionIO[Int] =
    findIdsDoneAndOlderThan(ts)
      .take(batch.toLong)
      .evalMap(delete)
      .map(_ => 1)
      .compile
      .foldMonoid

  def findNonFinalByTracker(trackerId: Ident): ConnectionIO[Option[RJob]] =
    run(
      select(T.all),
      from(T),
      where(T.tracker === trackerId, T.state.in(JobState.notDone))
    ).query[RJob].option

  def getUnfinishedCount(group: Ident): ConnectionIO[Int] =
    run(
      select(count(T.id)),
      from(T),
      T.group === group && T.state.in(JobState.notDone)
    ).query[Int].unique
}
