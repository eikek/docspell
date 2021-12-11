/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restapi.codec

import docspell.notification.api.ChannelRef
import docspell.restapi.model._

import io.circe.syntax._
import io.circe.{Decoder, Encoder}

trait ChannelEitherCodec {

  implicit val channelDecoder: Decoder[Either[ChannelRef, NotificationChannel]] =
    NotificationChannel.jsonDecoder.either(ChannelRef.jsonDecoder).map(_.swap)

  implicit val channelEncoder: Encoder[Either[ChannelRef, NotificationChannel]] =
    Encoder.instance(_.fold(_.asJson, _.asJson))

}

object ChannelEitherCodec extends ChannelEitherCodec
