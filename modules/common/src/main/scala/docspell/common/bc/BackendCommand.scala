/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.bc

import docspell.common.Ident

import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.{deriveConfiguredDecoder, deriveConfiguredEncoder}
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

sealed trait BackendCommand {}

object BackendCommand {

  implicit val deriveConfig: Configuration =
    Configuration.default.withDiscriminator("command").withKebabCaseConstructorNames

  case class ItemUpdate(itemId: Ident, actions: List[ItemAction]) extends BackendCommand
  object ItemUpdate {
    implicit val jsonDecoder: Decoder[ItemUpdate] = deriveDecoder
    implicit val jsonEncoder: Encoder[ItemUpdate] = deriveEncoder
  }

  def item(itemId: Ident, actions: List[ItemAction]): BackendCommand =
    ItemUpdate(itemId, actions)

  case class AttachmentUpdate(
      itemId: Ident,
      attachId: Ident,
      actions: List[AttachmentAction]
  ) extends BackendCommand
  object AttachmentUpdate {
    implicit val jsonDecoder: Decoder[AttachmentUpdate] = deriveDecoder
    implicit val jsonEncoder: Encoder[AttachmentUpdate] = deriveEncoder
  }

  implicit val jsonDecoder: Decoder[BackendCommand] = deriveConfiguredDecoder
  implicit val jsonEncoder: Encoder[BackendCommand] = deriveConfiguredEncoder
}
