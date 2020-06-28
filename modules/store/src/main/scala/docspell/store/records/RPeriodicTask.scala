package docspell.store.records

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

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
    created: Timestamp
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
      task: Ident,
      group: Ident,
      args: String,
      subject: String,
      submitter: Ident,
      priority: Priority,
      timer: CalEvent
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
              group,
              args,
              subject,
              submitter,
              priority,
              None,
              None,
              timer,
              timer
                .nextElapse(now.atZone(Timestamp.UTC))
                .map(_.toInstant)
                .map(Timestamp.apply)
                .getOrElse(Timestamp.Epoch),
              now
            )
          }
      )

  def createJson[F[_]: Sync, A](
      enabled: Boolean,
      task: Ident,
      group: Ident,
      args: A,
      subject: String,
      submitter: Ident,
      priority: Priority,
      timer: CalEvent
  )(implicit E: Encoder[A]): F[RPeriodicTask] =
    create[F](enabled, task, group, E(args).noSpaces, subject, submitter, priority, timer)

  val table = fr"periodic_task"

  object Columns {
    val id        = Column("id")
    val enabled   = Column("enabled")
    val task      = Column("task")
    val group     = Column("group_")
    val args      = Column("args")
    val subject   = Column("subject")
    val submitter = Column("submitter")
    val priority  = Column("priority")
    val worker    = Column("worker")
    val marked    = Column("marked")
    val timer     = Column("timer")
    val nextrun   = Column("nextrun")
    val created   = Column("created")
    val all = List(
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
      created
    )
  }

  import Columns._

  def insert(v: RPeriodicTask): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      all,
      fr"${v.id},${v.enabled},${v.task},${v.group},${v.args}," ++
        fr"${v.subject},${v.submitter},${v.priority},${v.worker}," ++
        fr"${v.marked},${v.timer},${v.nextrun},${v.created}"
    )
    sql.update.run
  }

  def update(v: RPeriodicTask): ConnectionIO[Int] = {
    val sql = updateRow(
      table,
      id.is(v.id),
      commas(
        enabled.setTo(v.enabled),
        group.setTo(v.group),
        args.setTo(v.args),
        subject.setTo(v.subject),
        submitter.setTo(v.submitter),
        priority.setTo(v.priority),
        worker.setTo(v.worker),
        marked.setTo(v.marked),
        timer.setTo(v.timer),
        nextrun.setTo(v.nextrun)
      )
    )
    sql.update.run
  }

  def exists(pid: Ident): ConnectionIO[Boolean] =
    selectCount(id, table, id.is(pid)).query[Int].unique.map(_ > 0)
}
