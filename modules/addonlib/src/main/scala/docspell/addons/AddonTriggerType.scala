/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.data.NonEmptyList

import io.circe.{Decoder, Encoder}

sealed trait AddonTriggerType {
  def name: String
}

object AddonTriggerType {

  /** The final step when processing an item. */
  case object FinalProcessItem extends AddonTriggerType {
    val name = "final-process-item"
  }

  /** The final step when reprocessing an item. */
  case object FinalReprocessItem extends AddonTriggerType {
    val name = "final-reprocess-item"
  }

  /** Running periodically based on a schedule. */
  case object Scheduled extends AddonTriggerType {
    val name = "scheduled"
  }

  /** Running (manually) on some existing item. */
  case object ExistingItem extends AddonTriggerType {
    val name = "existing-item"
  }

  val all: NonEmptyList[AddonTriggerType] =
    NonEmptyList.of(FinalProcessItem, FinalReprocessItem, Scheduled, ExistingItem)

  def fromString(str: String): Either[String, AddonTriggerType] =
    all
      .find(e => e.name.equalsIgnoreCase(str))
      .toRight(s"Invalid addon trigger type: $str")

  def unsafeFromString(str: String): AddonTriggerType =
    fromString(str).fold(sys.error, identity)

  implicit val jsonEncoder: Encoder[AddonTriggerType] =
    Encoder.encodeString.contramap(_.name)

  implicit val jsonDecoder: Decoder[AddonTriggerType] =
    Decoder.decodeString.emap(fromString)
}
