/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

final case class FileIntegrityCheckArgs(pattern: FileKeyPart) {}

object FileIntegrityCheckArgs {
  val taskName: Ident = Ident.unsafe("all-file-integrity-check")

  implicit val jsonDecoder: Decoder[FileIntegrityCheckArgs] =
    deriveDecoder

  implicit val jsonEncoder: Encoder[FileIntegrityCheckArgs] =
    deriveEncoder
}
