/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import docspell.common._

import emil.MailAddress
import io.circe.generic.semiauto
import io.circe.{Decoder, Encoder}

final case class PeriodicQueryArgs(
    account: AccountId,
    channel: ChannelOrRef,
    query: Option[ItemQueryString],
    bookmark: Option[String],
    baseUrl: Option[LenientUri]
)

object PeriodicQueryArgs {
  val taskName = Ident.unsafe("periodic-query-notify")

  implicit def jsonDecoder(implicit
      mc: Decoder[MailAddress]
  ): Decoder[PeriodicQueryArgs] = {
    implicit val x = ChannelOrRef.jsonDecoder
    semiauto.deriveDecoder
  }

  implicit def jsonEncoder(implicit
      mc: Encoder[MailAddress]
  ): Encoder[PeriodicQueryArgs] = {
    implicit val x = ChannelOrRef.jsonEncoder
    semiauto.deriveEncoder
  }
}
