/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

case class FileKey(collective: Ident, category: FileCategory, id: Ident)

object FileKey {

  implicit val jsonDecoder: Decoder[FileKey] =
    deriveDecoder[FileKey]

  implicit val jsonEncoder: Encoder[FileKey] =
    deriveEncoder[FileKey]
}
