/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.msg

import docspell.common._
import docspell.pubsub.api.{Topic, TypedTopic}

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

/** Message to notify about finished jobs. They have a final state. */
final case class JobDone(jobId: Ident, task: Ident, args: String, state: JobState)
object JobDone {
  implicit val jsonDecoder: Decoder[JobDone] =
    deriveDecoder[JobDone]

  implicit val jsonEncoder: Encoder[JobDone] =
    deriveEncoder[JobDone]

  val topic: TypedTopic[JobDone] =
    TypedTopic(Topic("job-finished"))
}
