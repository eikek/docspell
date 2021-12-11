/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import docspell.common.Ident

import io.circe.Decoder
import io.circe.Encoder
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}

final case class ChannelRef(id: Ident, channelType: ChannelType)

object ChannelRef {

  implicit val jsonDecoder: Decoder[ChannelRef] =
    deriveDecoder

  implicit val jsonEncoder: Encoder[ChannelRef] =
    deriveEncoder
}
