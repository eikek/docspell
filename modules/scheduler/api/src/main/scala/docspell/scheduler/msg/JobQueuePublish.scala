/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.msg

import cats.effect._
import cats.implicits._
import docspell.common.{Duration, Ident, Priority}
import docspell.notification.api.{Event, EventSink}
import docspell.pubsub.api.PubSubT
import docspell.scheduler.JobQueue
import docspell.store.Store
import docspell.store.records.RJob

final class JobQueuePublish[F[_]: Sync](
    delegate: JobQueue[F],
    pubsub: PubSubT[F],
    eventSink: EventSink[F]
) extends JobQueue[F] {

  private def msg(job: RJob): JobSubmitted =
    JobSubmitted(job.id, job.group, job.task, job.args)

  private def event(job: RJob): Event.JobSubmitted =
    Event.JobSubmitted(
      job.id,
      job.group,
      job.task,
      job.args,
      job.state,
      job.subject,
      job.submitter
    )

  private def publish(job: RJob): F[Unit] =
    pubsub.publish1(JobSubmitted.topic, msg(job)).as(()) *>
      eventSink.offer(event(job))

  def insert(job: RJob) =
    delegate.insert(job).flatTap(_ => publish(job))

  def insertIfNew(job: RJob) =
    delegate.insertIfNew(job).flatTap {
      case true  => publish(job)
      case false => ().pure[F]
    }

  def insertAll(jobs: Seq[RJob]) =
    delegate.insertAll(jobs).flatTap { results =>
      results.zip(jobs).traverse { case (res, job) =>
        if (res) publish(job)
        else ().pure[F]
      }
    }

  def insertAllIfNew(jobs: Seq[RJob]) =
    delegate.insertAllIfNew(jobs).flatTap { results =>
      results.zip(jobs).traverse { case (res, job) =>
        if (res) publish(job)
        else ().pure[F]
      }
    }

  def nextJob(prio: Ident => F[Priority], worker: Ident, retryPause: Duration) =
    delegate.nextJob(prio, worker, retryPause)
}

object JobQueuePublish {
  def apply[F[_]: Async](
      store: Store[F],
      pubSub: PubSubT[F],
      eventSink: EventSink[F]
  ): Resource[F, JobQueue[F]] =
    JobQueue.create(store).map(q => new JobQueuePublish[F](q, pubSub, eventSink))
}
