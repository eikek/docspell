/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.scheduler.{Job, JobStore}
import docspell.store.queries.QPeriodicTask
import docspell.store.records._
import docspell.store.{AddResult, Store}

trait PeriodicTaskStore[F[_]] {

  /** Get the free periodic task due next and reserve it to the given worker.
    *
    * If found, the task is returned and resource finalization takes care of unmarking the
    * task after use and updating `nextRun` with the next timestamp.
    */
  def takeNext(
      worker: Ident,
      excludeId: Option[Ident]
  ): Resource[F, Marked[RPeriodicTask]]

  def clearMarks(name: Ident): F[Unit]

  def findNonFinalJob(pjobId: Ident): F[Option[RJob]]

  /** Insert a task or update if it already exists. */
  def insert(task: RPeriodicTask): F[Unit]

  /** Adds the task only if it not already exists. */
  def add(task: RPeriodicTask): F[AddResult]

  /** Find all joex nodes as registered in the database. */
  def findJoexNodes: F[Vector[RNode]]

  /** Creates a job from the given task and submits it into the job queue */
  def submit(task: RPeriodicTask): F[Unit]
}

object PeriodicTaskStore {

  def apply[F[_]: Sync](
      store: Store[F],
      jobStore: JobStore[F]
  ): PeriodicTaskStore[F] =
    new PeriodicTaskStore[F] {
      private[this] val logger = docspell.logging.getLogger[F]
      def takeNext(
          worker: Ident,
          excludeId: Option[Ident]
      ): Resource[F, Marked[RPeriodicTask]] = {
        val chooseNext: F[Marked[RPeriodicTask]] =
          getNext(excludeId).flatMap {
            case Some(pj) =>
              mark(pj.id, worker).map {
                case true  => Marked.found(pj.copy(worker = worker.some))
                case false => Marked.notMarkable
              }
            case None =>
              Marked.notFound[RPeriodicTask].pure[F]
          }

        Resource.make(chooseNext) {
          case Marked.Found(pj) => unmark(pj)
          case _                => ().pure[F]
        }
      }

      def getNext(excl: Option[Ident]): F[Option[RPeriodicTask]] =
        store.transact(QPeriodicTask.findNext(excl))

      def mark(pid: Ident, name: Ident): F[Boolean] =
        Timestamp
          .current[F]
          .flatMap(now =>
            store.transact(QPeriodicTask.setWorker(pid, name, now)).map(_ > 0)
          )

      def unmark(job: RPeriodicTask): F[Unit] =
        for {
          now <- Timestamp.current[F]
          nextRun = job.timer.nextElapse(now.atUTC).map(Timestamp.from)
          _ <- store.transact(QPeriodicTask.unsetWorker(job.id, nextRun))
        } yield ()

      def clearMarks(name: Ident): F[Unit] =
        store
          .transact(QPeriodicTask.clearWorkers(name))
          .flatMap { n =>
            if (n > 0) logger.info(s"Clearing $n periodic tasks from worker ${name.id}")
            else ().pure[F]
          }

      def findNonFinalJob(pjobId: Ident): F[Option[RJob]] =
        store.transact(RJob.findNonFinalByTracker(pjobId))

      def insert(task: RPeriodicTask): F[Unit] = {
        val update = store.transact(RPeriodicTask.update(task))
        val insertAttempt = store.transact(RPeriodicTask.insert(task)).attempt.map {
          case Right(n) => n > 0
          case Left(_)  => false
        }

        for {
          n1 <- update
          ins <- if (n1 == 0) insertAttempt else true.pure[F]
          _ <- if (ins) 1.pure[F] else update
        } yield ()
      }

      def add(task: RPeriodicTask): F[AddResult] = {
        val insert = RPeriodicTask.insert(task)
        val exists = RPeriodicTask.exists(task.id)
        store.add(insert, exists)
      }

      def findJoexNodes: F[Vector[RNode]] =
        store.transact(RNode.findAll(NodeType.Joex))

      def submit(task: RPeriodicTask) =
        makeJob(task).flatMap(jobStore.insert)

      def makeJob(rt: RPeriodicTask): F[Job[String]] =
        Ident.randomId[F].map { id =>
          Job(
            id,
            rt.task,
            rt.group,
            rt.args,
            rt.subject,
            rt.submitter,
            rt.priority,
            Some(id)
          )
        }

    }
}
