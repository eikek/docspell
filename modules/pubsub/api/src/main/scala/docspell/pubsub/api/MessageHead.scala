/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.api

import docspell.common.{Ident, Timestamp}

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

final case class MessageHead(id: Ident, send: Timestamp, topic: Topic)

object MessageHead {
  implicit val jsonDecoder: Decoder[MessageHead] =
    deriveDecoder[MessageHead]

  implicit val jsonEncoder: Encoder[MessageHead] =
    deriveEncoder[MessageHead]
}
