package docspell.joex.scheduler

import cats.Functor
import cats.effect.{Blocker, Concurrent}
import cats.implicits._
import docspell.common._
import docspell.store.Store
import docspell.store.records.RJob
import docspell.common.syntax.all._
import org.log4s.{Logger => _, _}

trait Context[F[_], A] { self =>

  def jobId: Ident

  def args: A

  def config: SchedulerConfig

  def logger: Logger[F]

  def setProgress(percent: Int): F[Unit]

  def store: Store[F]

  def blocker: Blocker

  def map[C](f: A => C)(implicit F: Functor[F]): Context[F, C] =
    new Context.ContextImpl[F, C](f(args), logger, store, blocker, config, jobId)
}

object Context {
  private[this] val log = getLogger

  def create[F[_]: Functor, A](
      job: RJob,
      arg: A,
      config: SchedulerConfig,
      log: Logger[F],
      store: Store[F],
      blocker: Blocker
  ): Context[F, A] =
    new ContextImpl(arg, log, store, blocker, config, job.id)

  def apply[F[_]: Concurrent, A](
      job: RJob,
      arg: A,
      config: SchedulerConfig,
      logSink: LogSink[F],
      blocker: Blocker,
      store: Store[F]
  ): F[Context[F, A]] =
    for {
      _      <- log.ftrace("Creating logger for task run")
      logger <- Logger(job.id, job.info, config.logBufferSize, logSink)
      _      <- log.ftrace("Logger created, instantiating context")
      ctx    = create[F, A](job, arg, config, logger, store, blocker)
    } yield ctx

  final private class ContextImpl[F[_]: Functor, A](
      val args: A,
      val logger: Logger[F],
      val store: Store[F],
      val blocker: Blocker,
      val config: SchedulerConfig,
      val jobId: Ident
  ) extends Context[F, A] {

    def setProgress(percent: Int): F[Unit] = {
      val pval = math.min(100, math.max(0, percent))
      store.transact(RJob.setProgress(jobId, pval)).map(_ => ())
    }
  }
}
