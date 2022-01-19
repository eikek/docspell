/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration

import docspell.notification.api._

import emil.MailAddress
import io.circe.{Decoder, Encoder}

package object data {
  type ChannelOrRef = Either[ChannelRef, Channel]

  object ChannelOrRef {
    implicit def jsonDecoder(implicit mc: Decoder[MailAddress]): Decoder[ChannelOrRef] =
      Channel.jsonDecoder.either(ChannelRef.jsonDecoder).map(_.swap)

    implicit def jsonEncoder(implicit mc: Encoder[MailAddress]): Encoder[ChannelOrRef] =
      Encoder.instance(_.fold(ChannelRef.jsonEncoder.apply, Channel.jsonEncoder.apply))

    implicit class ChannelOrRefOpts(cr: ChannelOrRef) {
      def channelType: ChannelType =
        cr.fold(_.channelType, _.channelType)
    }
  }
}
