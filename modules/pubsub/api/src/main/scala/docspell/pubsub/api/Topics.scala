/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.api

import cats.data.NonEmptyList

import docspell.common.Ident

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

/** All topics used in Docspell. */
object Topics {

  /** Notify when a job has finished. */
  val jobDone: TypedTopic[JobDoneMsg] = TypedTopic[JobDoneMsg](Topic("job-done"))

  /** Notify when a job has been submitted. The job executor listens to these messages to
    * wake up and do its work.
    */
  val jobSubmitted: TypedTopic[JobSubmittedMsg] =
    TypedTopic[JobSubmittedMsg](Topic("job-submitted"))

  val all: NonEmptyList[TypedTopic[_]] = NonEmptyList.of(jobDone, jobSubmitted)

  final case class JobSubmittedMsg(id: Ident)
  object JobSubmittedMsg {
    implicit val jsonDecoder: Decoder[JobSubmittedMsg] =
      deriveDecoder[JobSubmittedMsg]

    implicit val jsonEncoder: Encoder[JobSubmittedMsg] =
      deriveEncoder[JobSubmittedMsg]
  }

  final case class JobDoneMsg(jobId: Ident, task: Ident)
  object JobDoneMsg {
    implicit val jsonDecoder: Decoder[JobDoneMsg] =
      deriveDecoder[JobDoneMsg]

    implicit val jsonEncoder: Encoder[JobDoneMsg] =
      deriveEncoder[JobDoneMsg]
  }
}
