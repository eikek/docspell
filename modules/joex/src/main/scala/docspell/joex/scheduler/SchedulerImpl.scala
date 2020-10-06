package docspell.joex.scheduler

import cats.data.OptionT
import cats.effect._
import cats.effect.concurrent.Semaphore
import cats.implicits._
import fs2.Stream
import fs2.concurrent.SignallingRef

import docspell.common._
import docspell.common.syntax.all._
import docspell.joex.scheduler.SchedulerImpl._
import docspell.store.Store
import docspell.store.queries.QJob
import docspell.store.queue.JobQueue
import docspell.store.records.RJob

import org.log4s._

final class SchedulerImpl[F[_]: ConcurrentEffect: ContextShift](
    val config: SchedulerConfig,
    blocker: Blocker,
    queue: JobQueue[F],
    tasks: JobTaskRegistry[F],
    store: Store[F],
    logSink: LogSink[F],
    state: SignallingRef[F, State[F]],
    waiter: SignallingRef[F, Boolean],
    permits: Semaphore[F]
) extends Scheduler[F] {

  private[this] val logger = getLogger

  /** On startup, get all jobs in state running from this scheduler
    * and put them into waiting state, so they get picked up again.
    */
  def init: F[Unit] =
    QJob.runningToWaiting(config.name, store)

  def periodicAwake(implicit T: Timer[F]): F[Fiber[F, Unit]] =
    ConcurrentEffect[F].start(
      Stream
        .awakeEvery[F](config.wakeupPeriod.toScala)
        .evalMap(_ => logger.fdebug("Periodic awake reached") *> notifyChange)
        .compile
        .drain
    )

  def getRunning: F[Vector[RJob]] =
    state.get.flatMap(s => QJob.findAll(s.getRunning, store))

  def requestCancel(jobId: Ident): F[Boolean] =
    state.get.flatMap(_.cancelRequest(jobId) match {
      case Some(ct) => ct.map(_ => true)
      case None =>
        (for {
          job <- OptionT(store.transact(RJob.findByIdAndWorker(jobId, config.name)))
          _ <- OptionT.liftF(
            if (job.isInProgress) executeCancel(job)
            else ().pure[F]
          )
        } yield true)
          .getOrElseF(
            logger.fwarn(s"Job ${jobId.id} not found, cannot cancel.").map(_ => false)
          )
    })

  def notifyChange: F[Unit] =
    waiter.update(b => !b)

  def shutdown(cancelAll: Boolean): F[Unit] = {
    val doCancel =
      state.get.flatMap(_.cancelTokens.values.toList.traverse(identity)).map(_ => ())

    val runShutdown =
      state.modify(_.requestShutdown) *> (if (cancelAll) doCancel else ().pure[F])

    val wait = Stream
      .eval(runShutdown)
      .evalMap(_ => logger.finfo("Scheduler is shutting down now."))
      .flatMap(_ =>
        Stream.eval(state.get) ++ Stream
          .suspend(state.discrete.takeWhile(_.getRunning.nonEmpty))
      )
      .flatMap { state =>
        if (state.getRunning.isEmpty) Stream.eval(logger.finfo("No jobs running."))
        else
          Stream.eval(
            logger.finfo(s"Waiting for ${state.getRunning.size} jobs to finish.")
          ) ++
            Stream.emit(state)
      }

    (wait.drain ++ Stream.emit(())).compile.lastOrError
  }

  def start: Stream[F, Nothing] =
    logger.sinfo("Starting scheduler") ++
      mainLoop

  def mainLoop: Stream[F, Nothing] = {
    val body: F[Boolean] =
      for {
        _ <- permits.available.flatMap(a =>
          logger.fdebug(s"Try to acquire permit ($a free)")
        )
        _    <- permits.acquire
        _    <- logger.fdebug("New permit acquired")
        down <- state.get.map(_.shutdownRequest)
        rjob <-
          if (down)
            logger.finfo("") *> permits.release *> (None: Option[RJob]).pure[F]
          else
            queue.nextJob(
              group => state.modify(_.nextPrio(group, config.countingScheme)),
              config.name,
              config.retryDelay
            )
        _ <- logger.fdebug(s"Next job found: ${rjob.map(_.info)}")
        _ <- rjob.map(execute).getOrElse(permits.release)
      } yield rjob.isDefined

    Stream
      .eval(state.get.map(_.shutdownRequest))
      .evalTap(
        if (_) logger.finfo[F]("Stopping main loop due to shutdown request.")
        else ().pure[F]
      )
      .flatMap(if (_) Stream.empty else Stream.eval(body))
      .flatMap({
        case true =>
          mainLoop
        case false =>
          logger.sdebug(s"Waiting for notify") ++
            waiter.discrete.take(2).drain ++
            logger.sdebug(s"Notify signal, going into main loop") ++
            mainLoop
      })
  }

  private def executeCancel(job: RJob): F[Unit] = {
    val task = for {
      jobtask <-
        tasks
          .find(job.task)
          .toRight(s"This executor cannot run tasks with name: ${job.task}")
    } yield jobtask

    task match {
      case Left(err) =>
        logger.ferror(s"Unable to run cancellation task for job ${job.info}: $err")
      case Right(t) =>
        for {
          _ <-
            logger.fdebug(s"Creating context for job ${job.info} to run cancellation $t")
          ctx <- Context[F, String](job, job.args, config, logSink, blocker, store)
          _   <- t.onCancel.run(ctx)
          _   <- state.modify(_.markCancelled(job))
          _   <- onFinish(job, JobState.Cancelled)
          _   <- ctx.logger.warn("Job has been cancelled.")
          _   <- logger.fdebug(s"Job ${job.info} has been cancelled.")
        } yield ()
    }
  }

  def execute(job: RJob): F[Unit] = {
    val task = for {
      jobtask <-
        tasks
          .find(job.task)
          .toRight(s"This executor cannot run tasks with name: ${job.task}")
    } yield jobtask

    task match {
      case Left(err) =>
        logger.ferror(s"Unable to start a task for job ${job.info}: $err")
      case Right(t) =>
        for {
          _   <- logger.fdebug(s"Creating context for job ${job.info} to run $t")
          ctx <- Context[F, String](job, job.args, config, logSink, blocker, store)
          jot = wrapTask(job, t.task, ctx)
          tok <- forkRun(job, jot.run(ctx), t.onCancel.run(ctx), ctx)
          _   <- state.modify(_.addRunning(job, tok))
        } yield ()
    }
  }

  def onFinish(job: RJob, finalState: JobState): F[Unit] =
    for {
      _ <- logger.fdebug(s"Job ${job.info} done $finalState. Releasing resources.")
      _ <- permits.release *> permits.available.flatMap(a =>
        logger.fdebug(s"Permit released ($a free)")
      )
      _ <- state.modify(_.removeRunning(job))
      _ <- QJob.setFinalState(job.id, finalState, store)
    } yield ()

  def onStart(job: RJob): F[Unit] =
    QJob.setRunning(
      job.id,
      config.name,
      store
    ) //also increments retries if current state=stuck

  def wrapTask(
      job: RJob,
      task: Task[F, String, Unit],
      ctx: Context[F, String]
  ): Task[F, String, Unit] =
    task
      .mapF(fa =>
        onStart(job) *> logger.fdebug("Starting task now") *> blocker.blockOn(fa)
      )
      .mapF(_.attempt.flatMap({
        case Right(()) =>
          logger.info(s"Job execution successful: ${job.info}")
          ctx.logger.info("Job execution successful") *>
            (JobState.Success: JobState).pure[F]
        case Left(ex) =>
          state.get.map(_.wasCancelled(job)).flatMap {
            case true =>
              logger.error(ex)(s"Job ${job.info} execution failed (cancel = true)")
              ctx.logger.error(ex)("Job execution failed (cancel = true)") *>
                (JobState.Cancelled: JobState).pure[F]
            case false =>
              QJob.exceedsRetries(job.id, config.retries, store).flatMap {
                case true =>
                  logger.error(ex)(s"Job ${job.info} execution failed. Retries exceeded.")
                  ctx.logger
                    .error(ex)(s"Job ${job.info} execution failed. Retries exceeded.")
                    .map(_ => JobState.Failed: JobState)
                case false =>
                  logger.error(ex)(s"Job ${job.info} execution failed. Retrying later.")
                  ctx.logger
                    .error(ex)(s"Job ${job.info} execution failed. Retrying later.")
                    .map(_ => JobState.Stuck: JobState)
              }
          }
      }))
      .mapF(_.attempt.flatMap {
        case Right(jstate) =>
          onFinish(job, jstate)
        case Left(ex) =>
          logger.error(ex)(s"Error happened during post-processing of ${job.info}!")
          // we don't know the real outcome here…
          // since tasks should be idempotent, set it to stuck. if above has failed, this might fail anyways
          onFinish(job, JobState.Stuck)
      })

  def forkRun(
      job: RJob,
      code: F[Unit],
      onCancel: F[Unit],
      ctx: Context[F, String]
  ): F[F[Unit]] = {
    val bfa = blocker.blockOn(code)
    logger.fdebug(s"Forking job ${job.info}") *>
      ConcurrentEffect[F]
        .start(bfa)
        .map(fiber =>
          logger.fdebug(s"Cancelling job ${job.info}") *>
            fiber.cancel *>
            onCancel.attempt.map({
              case Right(_) => ()
              case Left(ex) =>
                logger.error(ex)(s"Task's cancelling code failed. Job ${job.info}.")
                ()
            }) *>
            state.modify(_.markCancelled(job)) *>
            onFinish(job, JobState.Cancelled) *>
            ctx.logger.warn("Job has been cancelled.") *>
            logger.fdebug(s"Job ${job.info} has been cancelled.")
        )
  }
}

object SchedulerImpl {

  def emptyState[F[_]]: State[F] =
    State(Map.empty, Set.empty, Map.empty, false)

  case class State[F[_]](
      counters: Map[Ident, CountingScheme],
      cancelled: Set[Ident],
      cancelTokens: Map[Ident, CancelToken[F]],
      shutdownRequest: Boolean
  ) {

    def nextPrio(group: Ident, initial: CountingScheme): (State[F], Priority) = {
      val (cs, prio) = counters.getOrElse(group, initial).nextPriority
      (copy(counters = counters.updated(group, cs)), prio)
    }

    def addRunning(job: RJob, token: CancelToken[F]): (State[F], Unit) =
      (
        State(counters, cancelled, cancelTokens.updated(job.id, token), shutdownRequest),
        ()
      )

    def removeRunning(job: RJob): (State[F], Unit) =
      (
        copy(cancelled = cancelled - job.id, cancelTokens = cancelTokens.removed(job.id)),
        ()
      )

    def markCancelled(job: RJob): (State[F], Unit) =
      (copy(cancelled = cancelled + job.id), ())

    def wasCancelled(job: RJob): Boolean =
      cancelled.contains(job.id)

    def cancelRequest(id: Ident): Option[F[Unit]] =
      cancelTokens.get(id)

    def getRunning: Seq[Ident] =
      cancelTokens.keys.toSeq

    def requestShutdown: (State[F], Unit) =
      (copy(shutdownRequest = true), ())
  }
}
