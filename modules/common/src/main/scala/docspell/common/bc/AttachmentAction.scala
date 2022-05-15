/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.bc

import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.{deriveConfiguredDecoder, deriveConfiguredEncoder}
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

sealed trait AttachmentAction {}

object AttachmentAction {

  implicit val deriveConfig: Configuration =
    Configuration.default.withDiscriminator("action").withKebabCaseConstructorNames

  case class SetExtractedText(text: Option[String]) extends AttachmentAction
  object SetExtractedText {
    implicit val jsonDecoder: Decoder[SetExtractedText] = deriveDecoder
    implicit val jsonEncoder: Encoder[SetExtractedText] = deriveEncoder
  }

  implicit val jsonDecoder: Decoder[AttachmentAction] = deriveConfiguredDecoder
  implicit val jsonEncoder: Encoder[AttachmentAction] = deriveConfiguredEncoder

}
