package docspell.scheduler.impl

import cats.effect.Sync
import cats.syntax.all._

import docspell.common.Timestamp
import docspell.scheduler._

import docspell.store.Store
import docspell.store.records.RJob

final class JobStoreImpl[F[_]: Sync](store: Store[F]) extends JobStore[F] {
  private[this] val logger = docspell.logging.getLogger[F]

  def insert(job: Job[String]): F[Unit] =
    for {
      now <- Timestamp.current[F]
      _ <- insert0(job, now)
    } yield ()

  def insert0(job: Job[String], submitted: Timestamp): F[Unit] =
    store
      .transact(RJob.insert(toRecord(job, submitted)))
      .flatMap { n =>
        if (n != 1)
          Sync[F]
            .raiseError(new Exception(s"Inserting job failed. Update count: $n"))
        else ().pure[F]
      }

  def insertIfNew(job: Job[String]): F[Boolean] =
    Timestamp.current[F].flatMap(now => insertIfNew0(job, now))

  def insertIfNew0(job: Job[String], submitted: Timestamp): F[Boolean] =
    for {
      rj <- job.tracker match {
        case Some(tid) =>
          store.transact(RJob.findNonFinalByTracker(tid))
        case None =>
          None.pure[F]
      }
      ret <-
        if (rj.isDefined) false.pure[F]
        else insert0(job, submitted).as(true)
    } yield ret

  def insertAll(jobs: Seq[Job[String]]): F[List[Boolean]] =
    Timestamp.current[F].flatMap { now =>
      jobs.toList
        .traverse(j => insert0(j, now).attempt)
        .flatMap(_.traverse {
          case Right(()) => true.pure[F]
          case Left(ex) =>
            logger.error(ex)("Could not insert job. Skipping it.").as(false)
        })
    }

  def insertAllIfNew(jobs: Seq[Job[String]]) =
    Timestamp.current[F].flatMap { now =>
      jobs.toList
        .traverse(j => insertIfNew0(j, now).attempt)
        .flatMap(_.traverse {
          case Right(true)  => true.pure[F]
          case Right(false) => false.pure[F]
          case Left(ex) =>
            logger.error(ex)("Could not insert job. Skipping it.").as(false)
        })
    }

  def toRecord(job: Job[String], timestamp: Timestamp): RJob =
    RJob.newJob(
      job.id,
      job.task,
      job.group,
      job.args,
      job.subject,
      timestamp,
      job.submitter,
      job.priority,
      job.tracker
    )
}

object JobStoreImpl {
  def apply[F[_]: Sync](store: Store[F]): JobStore[F] =
    new JobStoreImpl[F](store)
}
