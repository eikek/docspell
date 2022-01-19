/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.data

import docspell.common._

import emil.MailAddress
import io.circe.generic.semiauto
import io.circe.{Decoder, Encoder}

/** Arguments to the notification task.
  *
  * This tasks queries items with a due date and informs the user via mail.
  *
  * If the structure changes, there must be some database migration to update or remove
  * the json data of the corresponding task.
  */
final case class PeriodicDueItemsArgsOld(
    account: AccountId,
    channel: ChannelOrRef,
    remindDays: Int,
    daysBack: Option[Int],
    tagsInclude: List[Ident],
    tagsExclude: List[Ident],
    baseUrl: Option[LenientUri]
)

object PeriodicDueItemsArgsOld {
  val taskName = Ident.unsafe("periodic-due-items-notify")

  implicit def jsonDecoder(implicit
      mc: Decoder[MailAddress]
  ): Decoder[PeriodicDueItemsArgsOld] = {
    implicit val x = ChannelOrRef.jsonDecoder
    semiauto.deriveDecoder
  }

  implicit def jsonEncoder(implicit
      mc: Encoder[MailAddress]
  ): Encoder[PeriodicDueItemsArgsOld] = {
    implicit val x = ChannelOrRef.jsonEncoder
    semiauto.deriveEncoder
  }
}
