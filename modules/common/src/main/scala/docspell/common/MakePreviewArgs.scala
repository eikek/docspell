/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.generic.semiauto._
import io.circe.{Decoder, Encoder}

/** Arguments for the `MakePreviewTask` that generates a preview image for an attachment.
  *
  * It can replace the current preview image or only generate one, if it is missing.
  */
case class MakePreviewArgs(
    attachment: Ident,
    store: MakePreviewArgs.StoreMode
) extends TaskArguments

object MakePreviewArgs {

  val taskName = Ident.unsafe("make-preview")

  def replace(attach: Ident): MakePreviewArgs =
    MakePreviewArgs(attach, StoreMode.Replace)

  def whenMissing(attach: Ident): MakePreviewArgs =
    MakePreviewArgs(attach, StoreMode.WhenMissing)

  sealed trait StoreMode extends Product {
    final def name: String =
      productPrefix.toLowerCase()
  }
  object StoreMode {

    /** Replace any preview file that may already exist. */
    case object Replace extends StoreMode

    /** Only create a preview image, if it is missing. */
    case object WhenMissing extends StoreMode

    def fromString(str: String): Either[String, StoreMode] =
      Option(str).map(_.trim.toLowerCase()) match {
        case Some("replace")     => Right(Replace)
        case Some("whenmissing") => Right(WhenMissing)
        case _                   => Left(s"Invalid store mode: $str")
      }

    implicit val jsonEncoder: Encoder[StoreMode] =
      Encoder.encodeString.contramap(_.name)

    implicit val jsonDecoder: Decoder[StoreMode] =
      Decoder.decodeString.emap(fromString)
  }

  implicit val jsonEncoder: Encoder[MakePreviewArgs] =
    deriveEncoder[MakePreviewArgs]

  implicit val jsonDecoder: Decoder[MakePreviewArgs] =
    deriveDecoder[MakePreviewArgs]

}
