package docspell.store.queue

import cats.implicits._
import cats.effect.{Effect, Resource}
import docspell.common._
import docspell.common.syntax.all._
import docspell.store.Store
import docspell.store.queries.QJob
import docspell.store.records.RJob
import org.log4s._

trait JobQueue[F[_]] {

  def insert(job: RJob): F[Unit]

  def insertAll(jobs: Seq[RJob]): F[Unit]

  def nextJob(prio: Ident => F[Priority], worker: Ident, retryPause: Duration): F[Option[RJob]]
}

object JobQueue {
  private[this] val logger = getLogger

  def apply[F[_] : Effect](store: Store[F]): Resource[F, JobQueue[F]] =
    Resource.pure(new JobQueue[F] {

      def nextJob(prio: Ident => F[Priority], worker: Ident, retryPause: Duration): F[Option[RJob]] =
        logger.fdebug("Select next job") *> QJob.takeNextJob(store)(prio, worker, retryPause)

      def insert(job: RJob): F[Unit] =
        store.transact(RJob.insert(job)).
          flatMap({ n =>
            if (n != 1) Effect[F].raiseError(new Exception(s"Inserting job failed. Update count: $n"))
            else ().pure[F]
          })

      def insertAll(jobs: Seq[RJob]): F[Unit] =
        jobs.toList.traverse(j => insert(j).attempt).
          map(_.foreach {
            case Right(()) =>
            case Left(ex) =>
              logger.error(ex)("Could not insert job. Skipping it.")
          })

    })
}
