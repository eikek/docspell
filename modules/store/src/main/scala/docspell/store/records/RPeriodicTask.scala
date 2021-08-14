/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.usertask.UserTaskScope

import com.github.eikek.calev.CalEvent
import doobie._
import doobie.implicits._
import io.circe.Encoder

/** A periodic task is a special job description, that shares a few
  * properties of a `RJob`. It must provide all information to create
  * a `RJob` value eventually.
  */
case class RPeriodicTask(
    id: Ident,
    enabled: Boolean,
    task: Ident,
    group: Ident,
    args: String,
    subject: String,
    submitter: Ident,
    priority: Priority,
    worker: Option[Ident],
    marked: Option[Timestamp],
    timer: CalEvent,
    nextrun: Timestamp,
    created: Timestamp,
    summary: Option[String]
) {

  def toJob[F[_]: Sync]: F[RJob] =
    for {
      now <- Timestamp.current[F]
      jid <- Ident.randomId[F]
    } yield RJob(
      jid,
      task,
      group,
      args,
      subject,
      now,
      submitter,
      priority,
      JobState.Waiting,
      0,
      0,
      Some(id),
      None,
      None,
      None
    )
}

object RPeriodicTask {

  def create[F[_]: Sync](
      enabled: Boolean,
      scope: UserTaskScope,
      task: Ident,
      args: String,
      subject: String,
      priority: Priority,
      timer: CalEvent,
      summary: Option[String]
  ): F[RPeriodicTask] =
    Ident
      .randomId[F]
      .flatMap(id =>
        Timestamp
          .current[F]
          .map { now =>
            RPeriodicTask(
              id,
              enabled,
              task,
              scope.collective,
              args,
              subject,
              scope.fold(_.user, identity),
              priority,
              None,
              None,
              timer,
              timer
                .nextElapse(now.atZone(Timestamp.UTC))
                .map(_.toInstant)
                .map(Timestamp.apply)
                .getOrElse(Timestamp.Epoch),
              now,
              summary
            )
          }
      )

  def createJson[F[_]: Sync, A](
      enabled: Boolean,
      scope: UserTaskScope,
      task: Ident,
      args: A,
      subject: String,
      priority: Priority,
      timer: CalEvent,
      summary: Option[String]
  )(implicit E: Encoder[A]): F[RPeriodicTask] =
    create[F](
      enabled,
      scope,
      task,
      E(args).noSpaces,
      subject,
      priority,
      timer,
      summary
    )

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "periodic_task"

    val id        = Column[Ident]("id", this)
    val enabled   = Column[Boolean]("enabled", this)
    val task      = Column[Ident]("task", this)
    val group     = Column[Ident]("group_", this)
    val args      = Column[String]("args", this)
    val subject   = Column[String]("subject", this)
    val submitter = Column[Ident]("submitter", this)
    val priority  = Column[Priority]("priority", this)
    val worker    = Column[Ident]("worker", this)
    val marked    = Column[Timestamp]("marked", this)
    val timer     = Column[CalEvent]("timer", this)
    val nextrun   = Column[Timestamp]("nextrun", this)
    val created   = Column[Timestamp]("created", this)
    val summary   = Column[String]("summary", this)
    val all = NonEmptyList.of[Column[_]](
      id,
      enabled,
      task,
      group,
      args,
      subject,
      submitter,
      priority,
      worker,
      marked,
      timer,
      nextrun,
      created,
      summary
    )
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RPeriodicTask): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.id},${v.enabled},${v.task},${v.group},${v.args}," ++
        fr"${v.subject},${v.submitter},${v.priority},${v.worker}," ++
        fr"${v.marked},${v.timer},${v.nextrun},${v.created},${v.summary}"
    )

  def update(v: RPeriodicTask): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === v.id,
      DML.set(
        T.enabled.setTo(v.enabled),
        T.group.setTo(v.group),
        T.args.setTo(v.args),
        T.subject.setTo(v.subject),
        T.submitter.setTo(v.submitter),
        T.priority.setTo(v.priority),
        T.worker.setTo(v.worker),
        T.marked.setTo(v.marked),
        T.timer.setTo(v.timer),
        T.nextrun.setTo(v.nextrun),
        T.summary.setTo(v.summary)
      )
    )

  def exists(pid: Ident): ConnectionIO[Boolean] =
    run(select(count(T.id)), from(T), T.id === pid).query[Int].unique.map(_ > 0)
}
