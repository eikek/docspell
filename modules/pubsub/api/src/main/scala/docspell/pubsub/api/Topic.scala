/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.api

import io.circe.{Decoder, Encoder}

final case class Topic private (topic: String) {
  def name: String = topic
}

object Topic {
  implicit val jsonDecoder: Decoder[Topic] =
    Decoder.decodeString.map(Topic.apply)

  implicit val jsonEncoder: Encoder[Topic] =
    Encoder.encodeString.contramap(_.topic)

  def apply(name: String): Topic = {
    require(name.trim.nonEmpty)
    new Topic(name)
  }
}
