/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

import io.circe.generic.semiauto._
import io.circe.{Decoder, Encoder}

/** Arguments when re-processing an item.
  *
  * The `itemId` must exist and point to some item. If the attachment
  * list is non-empty, only those attachments are re-processed. They
  * must belong to the given item. If the list is empty, then all
  * attachments are re-processed.
  */
case class ReProcessItemArgs(itemId: Ident, attachments: List[Ident])

object ReProcessItemArgs {

  val taskName: Ident = Ident.unsafe("re-process-item")

  implicit val jsonEncoder: Encoder[ReProcessItemArgs] =
    deriveEncoder[ReProcessItemArgs]

  implicit val jsonDecoder: Decoder[ReProcessItemArgs] =
    deriveDecoder[ReProcessItemArgs]
}
