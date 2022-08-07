/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.task

import docspell.backend.ops.ODownloadAll.model.DownloadRequest
import docspell.common._

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

final case class DownloadZipArgs(account: AccountInfo, req: DownloadRequest)
    extends TaskArguments

object DownloadZipArgs {
  val taskName: Ident = Ident.unsafe("download-query-zip")

  implicit val jsonEncoder: Encoder[DownloadZipArgs] =
    deriveEncoder
  implicit val jsonDecoder: Decoder[DownloadZipArgs] =
    deriveDecoder
}
