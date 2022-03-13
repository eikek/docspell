/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.msg

import docspell.common._
import docspell.pubsub.api.{Topic, TypedTopic}

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

/** Message to request to cancel a job. */
final case class CancelJob(jobId: Ident, nodeId: Ident)

object CancelJob {
  implicit val jsonDecoder: Decoder[CancelJob] =
    deriveDecoder[CancelJob]

  implicit val jsonEncoder: Encoder[CancelJob] =
    deriveEncoder[CancelJob]

  val topic: TypedTopic[CancelJob] =
    TypedTopic(Topic("job-cancel-request"))
}
