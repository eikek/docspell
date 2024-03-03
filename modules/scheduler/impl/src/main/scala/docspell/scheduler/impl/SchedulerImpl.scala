/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import cats.data.OptionT
import cats.effect._
import cats.effect.std.Semaphore
import cats.implicits._
import fs2.Stream
import fs2.concurrent.SignallingRef

import docspell.common._
import docspell.notification.api.Event
import docspell.notification.api.EventSink
import docspell.pubsub.api.PubSubT
import docspell.scheduler._
import docspell.scheduler.impl.SchedulerImpl._
import docspell.scheduler.msg.{CancelJob, JobDone, JobsNotify}
import docspell.store.Store
import docspell.store.records.RJob

import io.circe.Json

final class SchedulerImpl[F[_]: Async](
    val config: SchedulerConfig,
    queue: JobQueue[F],
    pubSub: PubSubT[F],
    eventSink: EventSink[F],
    findJobOwner: FindJobOwner[F],
    tasks: JobTaskRegistry[F],
    store: Store[F],
    logSink: LogSink[F],
    state: SignallingRef[F, State[F]],
    waiter: SignallingRef[F, Boolean],
    permits: Semaphore[F]
) extends Scheduler[F] {

  private[this] val logger = docspell.logging.getLogger[F]

  def startSubscriptions =
    for {
      _ <- Async[F].start(pubSub.subscribeSink(JobsNotify()) { _ =>
        notifyChange
      })
      _ <- Async[F].start(pubSub.subscribeSink(CancelJob.topic) { msg =>
        requestCancel(msg.body.jobId).void
      })
    } yield ()

  /** On startup, get all jobs in state running from this scheduler and put them into
    * waiting state, so they get picked up again.
    */
  def init: F[Unit] =
    QJob.runningToWaiting(config.name, store)

  def periodicAwake: F[Fiber[F, Throwable, Unit]] =
    Async[F].start(
      Stream
        .awakeEvery[F](config.wakeupPeriod.toScala)
        .evalMap(_ => logger.debug("Periodic awake reached") *> notifyChange)
        .compile
        .drain
    )

  def getRunning: F[Vector[Job[String]]] =
    state.get
      .flatMap(s => QJob.findAll(s.getRunning, store))
      .map(_.map(convertJob))

  private def convertJob(rj: RJob): Job[String] =
    Job(
      rj.id,
      rj.task,
      rj.group,
      rj.args,
      rj.subject,
      rj.submitter,
      rj.priority,
      rj.tracker
    )

  def requestCancel(jobId: Ident): F[Boolean] =
    logger.info(s"Scheduler requested to cancel job: ${jobId.id}") *>
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
              logger.warn(s"Job ${jobId.id} not found, cannot cancel.").map(_ => false)
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
      .evalMap(_ => logger.info("Scheduler is shutting down now."))
      .flatMap(_ =>
        Stream.eval(state.get) ++ Stream
          .suspend(state.discrete.takeWhile(_.getRunning.nonEmpty))
      )
      .flatMap { state =>
        if (state.getRunning.isEmpty) Stream.eval(logger.info("No jobs running."))
        else
          Stream.eval(
            logger.info(s"Waiting for ${state.getRunning.size} jobs to finish.")
          ) ++
            Stream.emit(state)
      }

    (wait.drain ++ Stream.emit(())).compile.lastOrError
  }

  def start: Stream[F, Nothing] =
    logger.stream.info("Starting scheduler").drain ++
      mainLoop

  def mainLoop: Stream[F, Nothing] = {
    val body: F[Boolean] =
      for {
        _ <- permits.available.flatTap(a =>
          logger.debug(s"Try to acquire permit ($a free)")
        )
        _ <- permits.acquire
        _ <- logger.debug("New permit acquired")
        down <- state.get.map(_.shutdownRequest)
        rjob <-
          if (down) permits.release.as(Option.empty[RJob])
          else
            queue.nextJob(
              group => state.modify(_.nextPrio(group, config.countingScheme)),
              config.name,
              config.retryDelay
            )
        _ <- logger.debug(s"Next job found: ${rjob.map(_.info)}")
        _ <- rjob.map(execute).getOrElse(permits.release)
      } yield rjob.isDefined

    Stream
      .eval(state.get.map(_.shutdownRequest))
      .evalTap(
        if (_) logger.info("Stopping main loop due to shutdown request.")
        else ().pure[F]
      )
      .flatMap(if (_) Stream.empty else Stream.eval(body))
      .flatMap {
        case true =>
          mainLoop
        case false =>
          logger.stream.debug(s"Waiting for notify").drain ++
            waiter.discrete.take(2).drain ++
            logger.stream.debug(s"Notify signal, going into main loop").drain ++
            mainLoop
      }
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
        logger.error(s"Unable to run cancellation task for job ${job.info}: $err")
      case Right(t) =>
        for {
          _ <-
            logger.debug(s"Creating context for job ${job.info} to run cancellation $t")
          ctx <- ContextImpl[F, String](job, job.args, config, logSink, store)
          _ <- t.onCancel.run(ctx)
          _ <- state.modify(_.markCancelled(job))
          _ <- onFinish(job, JobTaskResult.empty, JobState.Cancelled)
          _ <- ctx.logger.warn("Job has been cancelled.")
          _ <- logger.debug(s"Job ${job.info} has been cancelled.")
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
        logger.error(s"Unable to start a task for job ${job.info}: $err")
      case Right(t) =>
        for {
          _ <- logger.debug(s"Creating context for job ${job.info} to run $t")
          ctx <- ContextImpl[F, String](job, job.args, config, logSink, store)
          jot = wrapTask(job, t.task, ctx)
          tok <- forkRun(job, jot.run(ctx), t.onCancel.run(ctx), ctx)
          _ <- state.modify(_.addRunning(job, tok))
        } yield ()
    }
  }

  private def onFinish(job: RJob, result: JobTaskResult, finishState: JobState): F[Unit] =
    for {
      _ <- logger.debug(s"Job ${job.info} done $finishState. Releasing resources.")
      _ <- permits.release *> permits.available.flatMap(a =>
        logger.debug(s"Permit released ($a free)")
      )
      _ <- state.modify(_.removeRunning(job))
      _ <- QJob.setFinalState(job.id, finishState, store)
      _ <- Sync[F].whenA(JobState.isDone(finishState))(
        logger.trace("Publishing JobDone event") *> pubSub.publish1IgnoreErrors(
          JobDone.topic,
          JobDone(job.id, job.group, job.task, job.args, finishState, result.json)
        )
      )
      _ <- Sync[F].whenA(JobState.isDone(finishState))(
        logger.trace("Sending JobDone to event sink") *> makeJobDoneEvent(job, result)
          .semiflatMap(eventSink.offer)
          .value
      )
    } yield ()

  private def makeJobDoneEvent(job: RJob, result: JobTaskResult) =
    for {
      acc <- OptionT(findJobOwner(convertJob(job))).flatTransform(acc =>
        logger.debug(s"Found job owner $acc for job $job").as(acc)
      )
      ev = Event.JobDone(
        acc,
        job.id,
        job.group,
        job.task,
        job.args,
        job.state,
        job.subject,
        job.submitter,
        result.json.getOrElse(Json.Null),
        result.message
      )
    } yield ev

  def onStart(job: RJob): F[Unit] =
    QJob.setRunning(
      job.id,
      config.name,
      store
    ) // also increments retries if current state=stuck

  def wrapTask(
      job: RJob,
      task: Task[F, String, JobTaskResult],
      ctx: Context[F, String]
  ): Task[F, String, Unit] =
    task
      .mapF(fa => onStart(job) *> logger.debug("Starting task now") *> fa)
      .mapF(_.attempt.flatMap {
        case Right(result) =>
          logger.info(s"Job execution successful: ${job.info}") *>
            ctx.logger.info("Job execution successful") *>
            (JobState.Success: JobState, result).pure[F]

        case Left(PermanentError(ex)) =>
          logger.warn(ex)("Task failed with permanent error") *>
            ctx.logger
              .warn(ex)("Task failed with permanent error!")
              .as(JobState.failed -> JobTaskResult.empty)

        case Left(ex) =>
          state.get.map(_.wasCancelled(job)).flatMap {
            case true =>
              logger.error(ex)(s"Job ${job.info} execution failed (cancel = true)") *>
                ctx.logger.error(ex)("Job execution failed (cancel = true)") *>
                (JobState.Cancelled: JobState, JobTaskResult.empty).pure[F]
            case false =>
              QJob.exceedsRetries(job.id, config.retries, store).flatMap {
                case true =>
                  logger
                    .error(ex)(s"Job ${job.info} execution failed. Retries exceeded.") *>
                    ctx.logger
                      .error(ex)(s"Job ${job.info} execution failed. Retries exceeded.")
                      .map(_ => (JobState.Failed: JobState, JobTaskResult.empty))
                case false =>
                  logger
                    .error(ex)(s"Job ${job.info} execution failed. Retrying later.") *>
                    ctx.logger
                      .error(ex)(s"Job ${job.info} execution failed. Retrying later.")
                      .map(_ => (JobState.Stuck: JobState, JobTaskResult.empty))
              }
          }
      })
      .mapF(_.attempt.flatMap {
        case Right((jstate, result)) =>
          onFinish(job, result, jstate)
        case Left(ex) =>
          logger.error(ex)(s"Error happened during post-processing of ${job.info}!")
          // we don't know the real outcome here…
          // since tasks should be idempotent, set it to stuck. if above has failed, this might fail anyways
          onFinish(job, JobTaskResult.empty, JobState.Stuck)
      })

  def forkRun(
      job: RJob,
      code: F[Unit],
      onCancel: F[Unit],
      ctx: Context[F, String]
  ): F[F[Unit]] =
    logger.debug(s"Forking job ${job.info}") *>
      Async[F]
        .start(code)
        .map(fiber =>
          logger.debug(s"Cancelling job ${job.info}") *>
            fiber.cancel *>
            onCancel.attempt.map {
              case Right(_) => ()
              case Left(ex) =>
                logger.error(ex)(s"Task's cancelling code failed. Job ${job.info}.")
                ()
            } *>
            state.modify(_.markCancelled(job)) *>
            onFinish(job, JobTaskResult.empty, JobState.Cancelled) *>
            ctx.logger.warn("Job has been cancelled.") *>
            logger.debug(s"Job ${job.info} has been cancelled.")
        )
}

object SchedulerImpl {

  type CancelToken[F[_]] = F[Unit]

  def emptyState[F[_]]: State[F] =
    State(Map.empty, Set.empty, Map.empty, shutdownRequest = false)

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
