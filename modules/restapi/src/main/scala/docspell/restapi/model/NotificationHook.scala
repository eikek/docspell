/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restapi.model

import docspell.common._
import docspell.jsonminiq.JsonMiniQuery
import docspell.notification.api.{ChannelRef, EventType}
import docspell.restapi.codec.ChannelEitherCodec

import io.circe.{Decoder, Encoder}

// this must comply to the definition in openapi.yml in `extraSchemas`
final case class NotificationHook(
    id: Ident,
    enabled: Boolean,
    channel: Either[ChannelRef, NotificationChannel],
    allEvents: Boolean,
    eventFilter: Option[JsonMiniQuery],
    events: List[EventType]
)

object NotificationHook {
  import ChannelEitherCodec._

  implicit val jsonDecoder: Decoder[NotificationHook] =
    io.circe.generic.semiauto.deriveDecoder
  implicit val jsonEncoder: Encoder[NotificationHook] =
    io.circe.generic.semiauto.deriveEncoder
}
