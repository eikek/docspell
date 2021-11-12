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

final case class JobSubmitted(jobId: Ident, group: Ident, task: Ident, args: String)

object JobSubmitted {

  implicit val jsonDecoder: Decoder[JobSubmitted] =
    deriveDecoder

  implicit val jsonEncoder: Encoder[JobSubmitted] =
    deriveEncoder

  val topic: TypedTopic[JobSubmitted] =
    TypedTopic(Topic("job-submitted"))
}
