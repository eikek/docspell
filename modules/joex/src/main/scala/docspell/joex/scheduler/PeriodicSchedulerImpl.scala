package docspell.joex.scheduler

import fs2._
import fs2.concurrent.SignallingRef
import cats.effect._
import cats.implicits._
import org.log4s.getLogger
import com.github.eikek.fs2calev._

import docspell.common._
import docspell.common.syntax.all._
import docspell.store.queue._
import docspell.store.records.RPeriodicTask

import PeriodicSchedulerImpl.State

/*
onStartUp:
- remove worker value from all of the current

Loop:
- get earliest pjob
- if none: stop
- if triggered:
  - mark worker, restart loop on fail
  - submit new job
    - check for non-final jobs of that name
    - if exist: log info
    - if not exist: submit
  - update next trigger (in both cases)
  - remove worker
  - restart loop
- if future
  - schedule notify
  - stop loop


onNotify:
- cancel current scheduled notify
- start Loop


onShutdown:
- nothing to do
 */

final class PeriodicSchedulerImpl[F[_]: ConcurrentEffect: ContextShift](
    val config: PeriodicSchedulerConfig,
    queue: JobQueue[F],
    store: PeriodicTaskStore[F],
    waiter: SignallingRef[F, Boolean],
    state: SignallingRef[F, State[F]],
    timer: Timer[F]
) extends PeriodicScheduler[F] {
  private[this] val logger              = getLogger
  implicit private val _timer: Timer[F] = timer

  def start: Stream[F, Nothing] =
    logger.sinfo("Starting periodic scheduler") ++
      mainLoop

  def shutdown: F[Unit] =
    state.modify(_.requestShutdown)

  def periodicAwake: F[Fiber[F, Unit]] =
    ConcurrentEffect[F].start(
      Stream
        .awakeEvery[F](config.wakeupPeriod.toScala)
        .evalMap(_ => logger.fdebug("Periodic awake reached") *> notifyChange)
        .compile
        .drain
    )

  def notifyChange: F[Unit] =
    waiter.update(b => !b)

  // internal

  /**
    * On startup, get all periodic jobs from this scheduler and remove
    * the mark, so they get picked up again.
    */
  def init: F[Unit] =
    logError("Error clearing marks")(store.clearMarks(config.name))

  def mainLoop: Stream[F, Nothing] = {
    val body: F[Boolean] =
      for {
        _   <- logger.fdebug(s"Going into main loop")
        now <- Timestamp.current[F]
        _   <- logger.fdebug(s"Looking for next periodic task")
        go <- logThrow("Error getting next task")(
          store
            .takeNext(config.name)
            .use({
              case Some(pj) =>
                logger
                  .fdebug(s"Found periodic task '${pj.subject}/${pj.timer.asString}'") *>
                  (if (isTriggered(pj, now)) submitJob(pj)
                   else scheduleNotify(pj)).map(_ => true)
              case None =>
                logger.fdebug("No periodic task found") *> false.pure[F]
            })
        )
      } yield go

    Stream
      .eval(state.get.map(_.shutdownRequest))
      .evalTap(
        if (_) logger.finfo[F]("Stopping main loop due to shutdown request.")
        else ().pure[F]
      )
      .flatMap(if (_) Stream.empty else Stream.eval(cancelNotify *> body))
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

  def isTriggered(pj: RPeriodicTask, now: Timestamp): Boolean =
    pj.timer.contains(now.value)

  def submitJob(pj: RPeriodicTask): F[Unit] =
    store
      .findNonFinalJob(pj.id)
      .flatMap({
        case Some(job) =>
          logger.finfo[F](
            s"There is already a job with non-final state '${job.state}' in the queue"
          )

        case None =>
          logger.finfo[F](s"Submitting job for periodic task '${pj.task.id}'") *>
            pj.toJob.flatMap(queue.insert)
      })

  def scheduleNotify(pj: RPeriodicTask): F[Unit] =
    ConcurrentEffect[F]
      .start(
        CalevFs2
          .sleep[F](pj.timer)
          .evalMap(_ => notifyChange)
          .compile
          .drain
      )
      .flatMap(fb => state.modify(_.setNotify(fb)))

  def cancelNotify: F[Unit] =
    state
      .modify(_.clearNotify)
      .flatMap({
        case Some(fb) =>
          fb.cancel
        case None =>
          ().pure[F]
      })

  private def logError(msg: => String)(fa: F[Unit]): F[Unit] =
    fa.attempt.flatMap {
      case Right(_) => ().pure[F]
      case Left(ex) => logger.ferror(ex)(msg).map(_ => ())
    }

  private def logThrow[A](msg: => String)(fa: F[A]): F[A] =
    fa.attempt
      .flatMap({
        case r @ Right(_) => (r: Either[Throwable, A]).pure[F]
        case l @ Left(ex) => logger.ferror(ex)(msg).map(_ => (l: Either[Throwable, A]))
      })
      .rethrow
}

object PeriodicSchedulerImpl {
  def emptyState[F[_]]: State[F] =
    State(false, None)

  case class State[F[_]](
      shutdownRequest: Boolean,
      scheduledNotify: Option[Fiber[F, Unit]]
  ) {
    def requestShutdown: (State[F], Unit) =
      (copy(shutdownRequest = true), ())

    def setNotify(fb: Fiber[F, Unit]): (State[F], Unit) =
      (copy(scheduledNotify = Some(fb)), ())

    def clearNotify: (State[F], Option[Fiber[F, Unit]]) =
      (copy(scheduledNotify = None), scheduledNotify)

  }
}
