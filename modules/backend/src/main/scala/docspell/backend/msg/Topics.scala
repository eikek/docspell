/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.msg

import cats.data.NonEmptyList

import docspell.pubsub.api.{Topic, TypedTopic}

/** All topics used in Docspell. */
object Topics {

  /** A generic notification to the job executors to look for new work. */
  val jobsNotify: TypedTopic[Unit] =
    TypedTopic[Unit](Topic("jobs-notify"))

  /** A list of all topics. It is required to list every topic in use here! */
  val all: NonEmptyList[TypedTopic[_]] =
    NonEmptyList.of(JobDone.topic, CancelJob.topic, jobsNotify, JobSubmitted.topic)
}
