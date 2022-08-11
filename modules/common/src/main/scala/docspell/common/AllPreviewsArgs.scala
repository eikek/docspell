/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.generic.semiauto._
import io.circe.{Decoder, Encoder}

/** Arguments for the `AllPreviewsTask` that submits tasks to generates a preview image
  * for attachments.
  *
  * It can replace the current preview image or only generate one, if it is missing. If no
  * collective is specified, it considers all attachments.
  */
case class AllPreviewsArgs(
    collective: Option[CollectiveId],
    storeMode: MakePreviewArgs.StoreMode
) extends TaskArguments

object AllPreviewsArgs {

  val taskName = Ident.unsafe("all-previews")

  implicit val jsonEncoder: Encoder[AllPreviewsArgs] =
    deriveEncoder[AllPreviewsArgs]
  implicit val jsonDecoder: Decoder[AllPreviewsArgs] =
    deriveDecoder[AllPreviewsArgs]
}
