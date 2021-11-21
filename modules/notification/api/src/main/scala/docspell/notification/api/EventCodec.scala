/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import docspell.notification.api.Event._

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

trait EventCodec {

  implicit val tagsChangedDecoder: Decoder[TagsChanged] = deriveDecoder
  implicit val tagsChangedEncoder: Encoder[TagsChanged] = deriveEncoder

  implicit val eventDecoder: Decoder[Event] =
    deriveDecoder
  implicit val eventEncoder: Encoder[Event] =
    deriveEncoder
}
