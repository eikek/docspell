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

sealed trait ItemAction {}

object ItemAction {
  implicit val deriveConfig: Configuration =
    Configuration.default.withDiscriminator("action").withKebabCaseConstructorNames

  case class AddTags(tags: Set[String]) extends ItemAction
  object AddTags {
    implicit val jsonDecoder: Decoder[AddTags] = deriveDecoder
    implicit val jsonEncoder: Encoder[AddTags] = deriveEncoder
  }

  case class ReplaceTags(tags: Set[String]) extends ItemAction
  object ReplaceTags {
    implicit val jsonDecoder: Decoder[ReplaceTags] = deriveDecoder
    implicit val jsonEncoder: Encoder[ReplaceTags] = deriveEncoder
  }

  case class RemoveTags(tags: Set[String]) extends ItemAction
  object RemoveTags {
    implicit val jsonDecoder: Decoder[RemoveTags] = deriveDecoder
    implicit val jsonEncoder: Encoder[RemoveTags] = deriveEncoder
  }

  case class RemoveTagsCategory(categories: Set[String]) extends ItemAction
  object RemoveTagsCategory {
    implicit val jsonDecoder: Decoder[RemoveTagsCategory] = deriveDecoder
    implicit val jsonEncoder: Encoder[RemoveTagsCategory] = deriveEncoder
  }

  case class SetFolder(folder: Option[String]) extends ItemAction
  object SetFolder {
    implicit val jsonDecoder: Decoder[SetFolder] = deriveDecoder
    implicit val jsonEncoder: Encoder[SetFolder] = deriveEncoder
  }

  case class SetCorrOrg(id: Option[Ident]) extends ItemAction
  object SetCorrOrg {
    implicit val jsonDecoder: Decoder[SetCorrOrg] = deriveDecoder
    implicit val jsonEncoder: Encoder[SetCorrOrg] = deriveEncoder
  }

  case class SetCorrPerson(id: Option[Ident]) extends ItemAction
  object SetCorrPerson {
    implicit val jsonDecoder: Decoder[SetCorrPerson] = deriveDecoder
    implicit val jsonEncoder: Encoder[SetCorrPerson] = deriveEncoder
  }

  case class SetConcPerson(id: Option[Ident]) extends ItemAction
  object SetConcPerson {
    implicit val jsonDecoder: Decoder[SetConcPerson] = deriveDecoder
    implicit val jsonEncoder: Encoder[SetConcPerson] = deriveEncoder
  }

  case class SetConcEquipment(id: Option[Ident]) extends ItemAction
  object SetConcEquipment {
    implicit val jsonDecoder: Decoder[SetConcEquipment] = deriveDecoder
    implicit val jsonEncoder: Encoder[SetConcEquipment] = deriveEncoder
  }

  case class SetField(field: Ident, value: String) extends ItemAction
  object SetField {
    implicit val jsonDecoder: Decoder[SetField] = deriveDecoder
    implicit val jsonEncoder: Encoder[SetField] = deriveEncoder
  }

  case class SetName(name: String) extends ItemAction
  object SetName {
    implicit val jsonDecoder: Decoder[SetName] = deriveDecoder
    implicit val jsonEncoder: Encoder[SetName] = deriveEncoder
  }

  case class SetNotes(notes: Option[String]) extends ItemAction
  object SetNotes {
    implicit val jsonDecoder: Decoder[SetNotes] = deriveDecoder
    implicit val jsonEncoder: Encoder[SetNotes] = deriveEncoder
  }

  case class AddNotes(notes: String, separator: Option[String]) extends ItemAction
  object AddNotes {
    implicit val jsonDecoder: Decoder[AddNotes] = deriveDecoder
    implicit val jsonEncoder: Encoder[AddNotes] = deriveEncoder
  }

  implicit val jsonDecoder: Decoder[ItemAction] = deriveConfiguredDecoder
  implicit val jsonEncoder: Encoder[ItemAction] = deriveConfiguredEncoder
}
