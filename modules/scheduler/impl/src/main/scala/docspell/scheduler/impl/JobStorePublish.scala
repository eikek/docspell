/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.common.{Ident, JobState}
import docspell.notification.api.{Event, EventSink}
import docspell.pubsub.api.PubSubT
import docspell.scheduler._
import docspell.scheduler.msg.{JobSubmitted, JobsNotify}
import docspell.store.Store

final class JobStorePublish[F[_]: Sync](
    delegate: JobStore[F],
    pubsub: PubSubT[F],
    eventSink: EventSink[F],
    findJobOwner: FindJobOwner[F]
) extends JobStore[F] {

  private def msg(job: Job[String]): JobSubmitted =
    JobSubmitted(job.id, job.group, job.task, job.args)

  private def event(job: Job[String]): OptionT[F, Event.JobSubmitted] =
    OptionT(findJobOwner(job))
      .map(
        Event.JobSubmitted(
          _,
          job.id,
          job.group,
          job.task,
          job.args,
          JobState.waiting,
          job.subject,
          job.submitter
        )
      )

  private def publish(job: Job[String]): F[Unit] =
    pubsub.publish1(JobSubmitted.topic, msg(job)).as(()) *>
      event(job).semiflatMap(eventSink.offer).value.void

  private def notifyJoex: F[Unit] =
    pubsub.publish1IgnoreErrors(JobsNotify(), ()).void

  def insert(job: Job[String]) =
    delegate.insert(job).flatTap(_ => publish(job) *> notifyJoex)

  def insertIfNew(job: Job[String]) =
    delegate.insertIfNew(job).flatTap {
      case true  => publish(job) *> notifyJoex
      case false => ().pure[F]
    }

  def insertAll(jobs: Seq[Job[String]]) =
    delegate
      .insertAll(jobs)
      .flatTap { results =>
        results.zip(jobs).traverse { case (res, job) =>
          if (res) publish(job)
          else ().pure[F]
        }
      }
      .flatTap(_ => notifyJoex)

  def insertAllIfNew(jobs: Seq[Job[String]]) =
    delegate
      .insertAllIfNew(jobs)
      .flatTap { results =>
        results.zip(jobs).traverse { case (res, job) =>
          if (res) publish(job)
          else ().pure[F]
        }
      }
      .flatTap(_ => notifyJoex)

  def findById(jobId: Ident) =
    delegate.findById(jobId)
}

object JobStorePublish {
  def apply[F[_]: Async](
      store: Store[F],
      pubSub: PubSubT[F],
      eventSink: EventSink[F],
      findJobOwner: FindJobOwner[F]
  ): JobStore[F] =
    new JobStorePublish[F](JobStoreImpl(store), pubSub, eventSink, findJobOwner)
}
