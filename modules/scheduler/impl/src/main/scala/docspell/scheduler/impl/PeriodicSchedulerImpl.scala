/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import cats.effect._
import cats.implicits._
import fs2._
import fs2.concurrent.SignallingRef

import docspell.common._
import docspell.pubsub.api.PubSubT
import docspell.scheduler._
import docspell.scheduler.impl.PeriodicSchedulerImpl.State
import docspell.scheduler.msg.{JobsNotify, PeriodicTaskNotify}
import docspell.store.records.RPeriodicTask

import com.github.eikek.calev.fs2.{Scheduler => CalevScheduler}

final class PeriodicSchedulerImpl[F[_]: Async](
    val config: PeriodicSchedulerConfig,
    store: PeriodicTaskStore[F],
    pubSub: PubSubT[F],
    waiter: SignallingRef[F, Boolean],
    state: SignallingRef[F, State[F]]
) extends PeriodicScheduler[F] {
  private[this] val logger = docspell.logging.getLogger[F]

  def start: Stream[F, Nothing] =
    logger.stream.info("Starting periodic scheduler").drain ++
      mainLoop

  def shutdown: F[Unit] =
    state.modify(_.requestShutdown)

  def periodicAwake: F[Fiber[F, Throwable, Unit]] =
    Async[F].start(
      Stream
        .awakeEvery[F](config.wakeupPeriod.toScala)
        .evalMap(_ => logger.debug("Periodic awake reached") *> notifyChange)
        .compile
        .drain
    )

  def notifyChange: F[Unit] =
    waiter.update(b => !b)

  def startSubscriptions: F[Unit] =
    for {
      _ <- Async[F].start(pubSub.subscribeSink(PeriodicTaskNotify()) { _ =>
        logger.info("Notify periodic scheduler from message") *> notifyChange
      })
    } yield ()

  // internal

  /** On startup, get all periodic jobs from this scheduler and remove the mark, so they
    * get picked up again.
    */
  def init: F[Unit] =
    logError("Error clearing marks")(store.clearMarks(config.name))

  def mainLoop: Stream[F, Nothing] = {
    val body: F[Boolean] =
      for {
        _ <- logger.debug(s"Going into main loop")
        now <- Timestamp.current[F]
        _ <- logger.debug(s"Looking for next periodic task")
        go <- logThrow("Error getting next task")(
          store
            .takeNext(config.name, None)
            .use {
              case Marked.Found(pj) =>
                logger
                  .debug(s"Found periodic task '${pj.subject}/${pj.timer.asString}'") *>
                  (if (isTriggered(pj, now)) submitJob(pj)
                   else scheduleNotify(pj).map(_ => false))
              case Marked.NotFound =>
                logger.debug("No periodic task found") *> false.pure[F]
              case Marked.NotMarkable =>
                logger.debug("Periodic job cannot be marked. Trying again.") *> true
                  .pure[F]
            }
        )
      } yield go

    Stream
      .eval(state.get.map(_.shutdownRequest))
      .evalTap(
        if (_) logger.info("Stopping main loop due to shutdown request.")
        else ().pure[F]
      )
      .flatMap(if (_) Stream.empty else Stream.eval(cancelNotify *> body))
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

  def isTriggered(pj: RPeriodicTask, now: Timestamp): Boolean =
    pj.nextrun < now

  def submitJob(pj: RPeriodicTask): F[Boolean] =
    store
      .findNonFinalJob(pj.id)
      .flatMap {
        case Some(job) =>
          logger.info(
            s"There is already a job with non-final state '${job.state}' in the queue"
          ) *> scheduleNotify(pj) *> false.pure[F]

        case None =>
          logger.info(s"Submitting job for periodic task '${pj.task.id}'") *>
            store.submit(pj) *> notifyJoex *> true.pure[F]
      }

  def notifyJoex: F[Unit] =
    pubSub.publish1IgnoreErrors(JobsNotify(), ()).void

  def scheduleNotify(pj: RPeriodicTask): F[Unit] =
    Timestamp
      .current[F]
      .flatMap(now =>
        logger.debug(
          s"Scheduling next notify for timer ${pj.timer.asString} -> ${pj.timer.nextElapse(now.toUtcDateTime)}"
        )
      ) *>
      Async[F]
        .start(
          CalevScheduler
            .utc[F]
            .sleep(pj.timer)
            .evalMap(_ => notifyChange)
            .compile
            .drain
        )
        .flatMap(fb => state.modify(_.setNotify(fb)))

  def cancelNotify: F[Unit] =
    state
      .modify(_.clearNotify)
      .flatMap {
        case Some(fb) =>
          fb.cancel
        case None =>
          ().pure[F]
      }

  private def logError(msg: => String)(fa: F[Unit]): F[Unit] =
    fa.attempt.flatMap {
      case Right(_) => ().pure[F]
      case Left(ex) => logger.error(ex)(msg).map(_ => ())
    }

  private def logThrow[A](msg: => String)(fa: F[A]): F[A] =
    fa.attempt.flatMap {
      case r @ Right(_) => (r: Either[Throwable, A]).pure[F]
      case l @ Left(ex) => logger.error(ex)(msg).map(_ => l: Either[Throwable, A])
    }.rethrow
}

object PeriodicSchedulerImpl {
  def emptyState[F[_]]: State[F] =
    State(shutdownRequest = false, None)

  case class State[F[_]](
      shutdownRequest: Boolean,
      scheduledNotify: Option[Fiber[F, Throwable, Unit]]
  ) {
    def requestShutdown: (State[F], Unit) =
      (copy(shutdownRequest = true), ())

    def setNotify(fb: Fiber[F, Throwable, Unit]): (State[F], Unit) =
      (copy(scheduledNotify = Some(fb)), ())

    def clearNotify: (State[F], Option[Fiber[F, Throwable, Unit]]) =
      (copy(scheduledNotify = None), scheduledNotify)

  }
}
