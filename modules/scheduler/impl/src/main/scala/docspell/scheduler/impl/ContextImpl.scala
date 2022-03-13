package docspell.scheduler.impl

import cats._
import cats.syntax.all._
import cats.effect._

import docspell.common._
import docspell.logging.Logger
import docspell.scheduler._
import docspell.store.Store
import docspell.store.records.RJob

class ContextImpl[F[_]: Functor, A](
    val args: A,
    val logger: Logger[F],
    val store: Store[F],
    val config: SchedulerConfig,
    val jobId: Ident
) extends Context[F, A] {

  def setProgress(percent: Int): F[Unit] = {
    val pval = math.min(100, math.max(0, percent))
    store.transact(RJob.setProgress(jobId, pval)).map(_ => ())
  }

  def isLastRetry: F[Boolean] =
    for {
      current <- store.transact(RJob.getRetries(jobId))
      last = config.retries == current.getOrElse(0)
    } yield last

  def map[C](f: A => C) =
    new ContextImpl[F, C](f(args), logger, store, config, jobId)
}

object ContextImpl {
  def create[F[_]: Async, A](
      jobId: Ident,
      arg: A,
      config: SchedulerConfig,
      log: Logger[F],
      store: Store[F]
  ): Context[F, A] =
    new ContextImpl(arg, log, store, config, jobId)

  def apply[F[_]: Async, A](
      job: RJob,
      arg: A,
      config: SchedulerConfig,
      logSink: LogSink[F],
      store: Store[F]
  ): F[Context[F, A]] = {
    val log = docspell.logging.getLogger[F]
    for {
      _ <- log.trace("Creating logger for task run")
      logger <- QueueLogger(job.id, job.info, config.logBufferSize, logSink)
      _ <- log.trace("Logger created, instantiating context")
      ctx = create[F, A](job.id, arg, config, logger, store)
    } yield ctx
  }
}
