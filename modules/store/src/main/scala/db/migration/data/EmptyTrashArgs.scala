/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.data

import docspell.common._
import docspell.common.syntax.all._

import com.github.eikek.calev.CalEvent
import io.circe._
import io.circe.generic.semiauto._

/** Arguments to the empty-trash task.
  *
  * This task is run periodically to really delete all soft-deleted items. These are items
  * with state `ItemState.Deleted`.
  *
  * @deprecated
  *   This structure has been changed to use a `CollectiveId`
  */
case class EmptyTrashArgs(
    collective: Ident,
    minAge: Duration
) {

  def makeSubject: String =
    s"Empty Trash: Remove older than ${minAge.toJava}"

  def periodicTaskId: Ident =
    EmptyTrashArgs.periodicTaskId(collective)
}

object EmptyTrashArgs {

  val taskName = Ident.unsafe("empty-trash")

  val defaultSchedule = CalEvent.unsafe("*-*-1/7 03:00:00 UTC")

  def periodicTaskId(coll: Ident): Ident =
    Ident.unsafe(s"docspell") / taskName / coll

  implicit val jsonEncoder: Encoder[EmptyTrashArgs] =
    deriveEncoder[EmptyTrashArgs]
  implicit val jsonDecoder: Decoder[EmptyTrashArgs] =
    deriveDecoder[EmptyTrashArgs]

  def parse(str: String): Either[Throwable, EmptyTrashArgs] =
    str.parseJsonAs[EmptyTrashArgs]
}
