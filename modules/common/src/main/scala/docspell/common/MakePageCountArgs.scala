/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

import io.circe.generic.semiauto._
import io.circe.{Decoder, Encoder}

/** Arguments for the `MakePageCountTask` that reads the number of
  * pages for an attachment and stores it into the meta data of the
  * attachment.
  */
case class MakePageCountArgs(
    attachment: Ident
)

object MakePageCountArgs {

  val taskName = Ident.unsafe("make-page-count")

  implicit val jsonEncoder: Encoder[MakePageCountArgs] =
    deriveEncoder[MakePageCountArgs]

  implicit val jsonDecoder: Decoder[MakePageCountArgs] =
    deriveDecoder[MakePageCountArgs]

}
