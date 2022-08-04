/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.data

import cats.data.NonEmptyList
import docspell.common._
import docspell.notification.api.ChannelRef
import io.circe.generic.semiauto
import io.circe.{Decoder, Encoder}

/** Arguments to the notification task.
  *
  * This tasks queries items with a due date and informs the user via mail.
  *
  * If the structure changes, there must be some database migration to update or remove
  * the json data of the corresponding task.
  *
  * @deprecated
  *   replaced with a version using `AccountInfo`
  */
final case class PeriodicDueItemsArgs(
    account: AccountId,
    channels: NonEmptyList[ChannelRef],
    remindDays: Int,
    daysBack: Option[Int],
    tagsInclude: List[Ident],
    tagsExclude: List[Ident],
    baseUrl: Option[LenientUri]
)

object PeriodicDueItemsArgs {
  val taskName = Ident.unsafe("periodic-due-items-notify2")

  implicit val jsonDecoder: Decoder[PeriodicDueItemsArgs] =
    semiauto.deriveDecoder

  implicit val jsonEncoder: Encoder[PeriodicDueItemsArgs] =
    semiauto.deriveEncoder
}
