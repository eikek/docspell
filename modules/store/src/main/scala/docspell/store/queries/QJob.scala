package docspell.store.queries

import cats.data.NonEmptyList
import cats.effect.Effect
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.common.syntax.all._
import docspell.store.Store
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records.{RJob, RJobGroupUse, RJobLog}

import doobie._
import doobie.implicits._
import org.log4s._

object QJob {
  private[this] val logger = getLogger

  def takeNextJob[F[_]: Effect](
      store: Store[F]
  )(
      priority: Ident => F[Priority],
      worker: Ident,
      retryPause: Duration
  ): F[Option[RJob]] =
    Stream
      .range(0, 10)
      .evalMap(n => takeNextJob1(store)(priority, worker, retryPause, n))
      .evalTap { x =>
        if (x.isLeft)
          logger.fdebug[F](
            "Cannot mark job, probably due to concurrent updates. Will retry."
          )
        else ().pure[F]
      }
      .find(_.isRight)
      .flatMap({
        case Right(job) =>
          Stream.emit(job)
        case Left(_) =>
          Stream
            .eval(logger.fwarn[F]("Cannot mark job, even after retrying. Give up."))
            .map(_ => None)
      })
      .compile
      .last
      .map(_.flatten)

  private def takeNextJob1[F[_]: Effect](store: Store[F])(
      priority: Ident => F[Priority],
      worker: Ident,
      retryPause: Duration,
      currentTry: Int
  ): F[Either[Unit, Option[RJob]]] = {
    //if this fails, we have to restart takeNextJob
    def markJob(job: RJob): F[Either[Unit, RJob]] =
      store.transact(for {
        n <- RJob.setScheduled(job.id, worker)
        _ <-
          if (n == 1) RJobGroupUse.setGroup(RJobGroupUse(worker, job.group))
          else 0.pure[ConnectionIO]
      } yield if (n == 1) Right(job) else Left(()))

    for {
      _ <- logger.ftrace[F](
        s"About to take next job (worker ${worker.id}), try $currentTry"
      )
      now   <- Timestamp.current[F]
      group <- store.transact(selectNextGroup(worker, now, retryPause))
      _     <- logger.ftrace[F](s"Choose group ${group.map(_.id)}")
      prio  <- group.map(priority).getOrElse((Priority.Low: Priority).pure[F])
      _     <- logger.ftrace[F](s"Looking for job of prio $prio")
      job <-
        group
          .map(g => store.transact(selectNextJob(g, prio, retryPause, now)))
          .getOrElse((None: Option[RJob]).pure[F])
      _   <- logger.ftrace[F](s"Found job: ${job.map(_.info)}")
      res <- job.traverse(j => markJob(j))
    } yield res.map(_.map(_.some)).getOrElse {
      if (group.isDefined)
        Left(()) // if a group was found, but no job someone else was faster
      else Right(None)
    }
  }

  def selectNextGroup(
      worker: Ident,
      now: Timestamp,
      initialPause: Duration
  ): ConnectionIO[Option[Ident]] = {
    val JC = RJob.as("a")
    val G  = RJobGroupUse.as("b")

    val stuckTrigger = stuckTriggerValue(JC, initialPause, now)
    val stateCond =
      JC.state === JobState.waiting || (JC.state === JobState.stuck && stuckTrigger < now.toMillis)

    val sql1 =
      Select(
        List(max(JC.group).as("g")),
        from(JC).innerJoin(G, JC.group === G.group),
        G.worker === worker && stateCond
      )

    val sql2 =
      Select(List(min(JC.group).as("g")), from(JC), stateCond)

    val gcol = Column[String]("g", TableDef(""))
    val groups =
      Select(select(gcol), fromSubSelect(union(sql1, sql2)).as("t0"), gcol.isNull.negate)

    // either 0, one or two results, but may be empty if RJob table is empty
    groups.run.query[Ident].to[List].map(_.headOption)
  }

  private def stuckTriggerValue(t: RJob.Table, initialPause: Duration, now: Timestamp) =
    plus(
      coalesce(t.startedmillis.s, lit(now.toMillis)).s,
      mult(power(2, t.retries.s).s, lit(initialPause.millis)).s
    )

  def selectNextJob(
      group: Ident,
      prio: Priority,
      initialPause: Duration,
      now: Timestamp
  ): ConnectionIO[Option[RJob]] = {
    val JC = RJob.T
    val psort =
      if (prio == Priority.High) JC.priority.desc
      else JC.priority.asc
    val waiting = JobState.waiting
    val stuck   = JobState.stuck

    val stuckTrigger = stuckTriggerValue(JC, initialPause, now)
    val sql =
      Select(
        select(JC.all),
        from(JC),
        JC.group === group && (JC.state === waiting ||
          (JC.state === stuck && stuckTrigger < now.toMillis))
      ).orderBy(JC.state.asc, psort, JC.submitted.asc).limit(1)

    sql.run.query[RJob].option
  }

  def setCancelled[F[_]: Effect](id: Ident, store: Store[F]): F[Unit] =
    for {
      now <- Timestamp.current[F]
      _   <- store.transact(RJob.setCancelled(id, now))
    } yield ()

  def setFailed[F[_]: Effect](id: Ident, store: Store[F]): F[Unit] =
    for {
      now <- Timestamp.current[F]
      _   <- store.transact(RJob.setFailed(id, now))
    } yield ()

  def setSuccess[F[_]: Effect](id: Ident, store: Store[F]): F[Unit] =
    for {
      now <- Timestamp.current[F]
      _   <- store.transact(RJob.setSuccess(id, now))
    } yield ()

  def setStuck[F[_]: Effect](id: Ident, store: Store[F]): F[Unit] =
    for {
      now <- Timestamp.current[F]
      _   <- store.transact(RJob.setStuck(id, now))
    } yield ()

  def setRunning[F[_]: Effect](id: Ident, workerId: Ident, store: Store[F]): F[Unit] =
    for {
      now <- Timestamp.current[F]
      _   <- store.transact(RJob.setRunning(id, workerId, now))
    } yield ()

  def setFinalState[F[_]: Effect](id: Ident, state: JobState, store: Store[F]): F[Unit] =
    state match {
      case JobState.Success =>
        setSuccess(id, store)
      case JobState.Failed =>
        setFailed(id, store)
      case JobState.Cancelled =>
        setCancelled(id, store)
      case JobState.Stuck =>
        setStuck(id, store)
      case _ =>
        logger.ferror[F](s"Invalid final state: $state.")
    }

  def exceedsRetries[F[_]: Effect](id: Ident, max: Int, store: Store[F]): F[Boolean] =
    store.transact(RJob.getRetries(id)).map(n => n.forall(_ >= max))

  def runningToWaiting[F[_]: Effect](workerId: Ident, store: Store[F]): F[Unit] =
    store.transact(RJob.setRunningToWaiting(workerId)).map(_ => ())

  def findAll[F[_]: Effect](ids: Seq[Ident], store: Store[F]): F[Vector[RJob]] =
    store.transact(RJob.findFromIds(ids))

  def queueStateSnapshot(
      collective: Ident,
      max: Long
  ): Stream[ConnectionIO, (RJob, Vector[RJobLog])] = {
    val JC      = RJob.T
    val waiting = NonEmptyList.of(JobState.Waiting, JobState.Stuck, JobState.Scheduled)
    val running = NonEmptyList.of(JobState.Running)
    //val done                   = JobState.all.filterNot(js => ).diff(waiting).diff(running)

    def selectJobs(now: Timestamp): Stream[ConnectionIO, RJob] = {
      val refDate = now.minusHours(24)
      val runningJobs = Select(
        select(JC.all),
        from(JC),
        JC.group === collective && JC.state.in(running)
      ).orderBy(JC.submitted.desc).run.query[RJob].stream

      val waitingJobs = Select(
        select(JC.all),
        from(JC),
        JC.group === collective && JC.state.in(waiting) && JC.submitted > refDate
      ).orderBy(JC.submitted.desc).run.query[RJob].stream.take(max)

      val doneJobs = Select(
        select(JC.all),
        from(JC),
        and(
          JC.group === collective,
          JC.state.in(JobState.done),
          JC.submitted > refDate
        )
      ).orderBy(JC.submitted.desc).run.query[RJob].stream.take(max)

      runningJobs ++ waitingJobs ++ doneJobs
    }

    def selectLogs(job: RJob): ConnectionIO[Vector[RJobLog]] =
      RJobLog.findLogs(job.id)

    for {
      now <- Stream.eval(Timestamp.current[ConnectionIO])
      job <- selectJobs(now)
      res <- Stream.eval(selectLogs(job))
    } yield (job, res)
  }
}
