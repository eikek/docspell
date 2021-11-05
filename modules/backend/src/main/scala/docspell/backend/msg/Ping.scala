/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.msg

import java.util.concurrent.atomic.AtomicLong

import docspell.pubsub.api.{Topic, TypedTopic}

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

final case class Ping(sender: String, num: Long)

object Ping {
  implicit val jsonDecoder: Decoder[Ping] =
    deriveDecoder[Ping]

  implicit val jsonEncoder: Encoder[Ping] =
    deriveEncoder[Ping]

  private[this] val counter = new AtomicLong(0)
  def next(sender: String): Ping =
    Ping(sender, counter.getAndIncrement())

  val topic: TypedTopic[Ping] =
    TypedTopic[Ping](Topic("ping"))
}
