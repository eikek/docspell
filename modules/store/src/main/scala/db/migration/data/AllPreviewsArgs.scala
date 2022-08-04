/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.data

import docspell.common._
import io.circe.generic.semiauto._
import io.circe.{Decoder, Encoder}

/** Arguments for the `AllPreviewsTask` that submits tasks to generates a preview image
  * for attachments.
  *
  * It can replace the current preview image or only generate one, if it is missing. If no
  * collective is specified, it considers all attachments.
  *
  * @deprecated
  *   This structure has been replaced to use a `CollectiveId`
  */
case class AllPreviewsArgs(
    collective: Option[Ident],
    storeMode: MakePreviewArgs.StoreMode
)

object AllPreviewsArgs {

  val taskName = Ident.unsafe("all-previews")

  implicit val jsonEncoder: Encoder[AllPreviewsArgs] =
    deriveEncoder[AllPreviewsArgs]
  implicit val jsonDecoder: Decoder[AllPreviewsArgs] =
    deriveDecoder[AllPreviewsArgs]
}
