/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

import com.github.eikek.calev.CalEvent
import docspell.common.syntax.all._
import io.circe._
import io.circe.generic.semiauto._

/** Arguments to the empty-trash task.
  *
  * This task is run periodically to really delete all soft-deleted
  * items. These are items with state `ItemState.Deleted`.
  */
case class EmptyTrashArgs(
    collective: Ident
) {

  def makeSubject: String =
    "Empty trash"

}

object EmptyTrashArgs {

  val taskName = Ident.unsafe("empty-trash")

  val defaultSchedule = CalEvent.unsafe("*-*-1/7 03:00:00")

  implicit val jsonEncoder: Encoder[EmptyTrashArgs] =
    deriveEncoder[EmptyTrashArgs]
  implicit val jsonDecoder: Decoder[EmptyTrashArgs] =
    deriveDecoder[EmptyTrashArgs]

  def parse(str: String): Either[Throwable, EmptyTrashArgs] =
    str.parseJsonAs[EmptyTrashArgs]

}
