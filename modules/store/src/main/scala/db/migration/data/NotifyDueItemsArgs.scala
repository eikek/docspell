/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.data

import docspell.common._
import docspell.common.syntax.all._

import io.circe._
import io.circe.generic.semiauto._

/** Arguments to the notification task.
  *
  * This tasks queries items with a due date and informs the user via mail.
  *
  * If the structure changes, there must be some database migration to update or remove
  * the json data of the corresponding task.
  *
  * @deprecated
  *   note: This has been removed and copied to this place to be able to migrate away from
  *   this structure. Replaced by PeriodicDueItemsArgs
  */
case class NotifyDueItemsArgs(
    account: AccountId,
    smtpConnection: Ident,
    recipients: List[String],
    itemDetailUrl: Option[LenientUri],
    remindDays: Int,
    daysBack: Option[Int],
    tagsInclude: List[Ident],
    tagsExclude: List[Ident]
)

object NotifyDueItemsArgs {

  val taskName = Ident.unsafe("notify-due-items")

  implicit val jsonEncoder: Encoder[NotifyDueItemsArgs] =
    deriveEncoder[NotifyDueItemsArgs]
  implicit val jsonDecoder: Decoder[NotifyDueItemsArgs] =
    deriveDecoder[NotifyDueItemsArgs]

  def parse(str: String): Either[Throwable, NotifyDueItemsArgs] =
    str.parseJsonAs[NotifyDueItemsArgs]

}
