/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.scheduler

import cats.effect._
import cats.implicits._
import cats.{Applicative, Functor}

import docspell.common._
import docspell.logging.Logger
import docspell.store.Store
import docspell.store.records.RJob

trait Context[F[_], A] { self =>

  def jobId: Ident

  def args: A

  def config: SchedulerConfig

  def logger: Logger[F]

  def setProgress(percent: Int): F[Unit]

  def store: Store[F]

  final def isLastRetry(implicit ev: Applicative[F]): F[Boolean] =
    for {
      current <- store.transact(RJob.getRetries(jobId))
      last = config.retries == current.getOrElse(0)
    } yield last

  def map[C](f: A => C)(implicit F: Functor[F]): Context[F, C] =
    new Context.ContextImpl[F, C](f(args), logger, store, config, jobId)
}

object Context {

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

  final private class ContextImpl[F[_]: Functor, A](
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
  }
}
