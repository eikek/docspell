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

final case class PeriodicDueItemsArgs(
    account: AccountId,
    channel: ChannelOrRef,
    remindDays: Int,
    daysBack: Option[Int],
    tagsInclude: List[Ident],
    tagsExclude: List[Ident],
    baseUrl: Option[LenientUri]
)

object PeriodicDueItemsArgs {
  val taskName = Ident.unsafe("periodic-due-items-notify")

  implicit def jsonDecoder(implicit
      mc: Decoder[MailAddress]
  ): Decoder[PeriodicDueItemsArgs] = {
    implicit val x = ChannelOrRef.jsonDecoder
    semiauto.deriveDecoder
  }

  implicit def jsonEncoder(implicit
      mc: Encoder[MailAddress]
  ): Encoder[PeriodicDueItemsArgs] = {
    implicit val x = ChannelOrRef.jsonEncoder
    semiauto.deriveEncoder
  }
}
