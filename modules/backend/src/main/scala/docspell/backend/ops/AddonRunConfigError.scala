/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.NonEmptyList

import docspell.addons.{AddonArchive, AddonMeta, AddonTriggerType}

sealed trait AddonRunConfigError {
  final def cast: AddonRunConfigError = this

  def toLeft[A]: Either[AddonRunConfigError, A] = Left(this)

  def message: String
}

object AddonRunConfigError {

  case object MissingSchedule extends AddonRunConfigError {
    val message =
      "The run config has a trigger 'scheduled' but doesn't provide a schedule!"
  }

  case object ObsoleteSchedule extends AddonRunConfigError {
    val message = "The run config has a schedule, but not a trigger 'Scheduled'."
  }

  case class MismatchingTrigger(unsupported: NonEmptyList[(String, AddonTriggerType)])
      extends AddonRunConfigError {
    def message: String = {
      val list =
        unsupported.map { case (name, tt) => s"$name: ${tt.name}" }.toList.mkString(", ")
      s"Some listed addons don't support all defined triggers: $list"
    }
  }

  object MismatchingTrigger {
    def apply(addon: AddonMeta, tt: AddonTriggerType): MismatchingTrigger =
      MismatchingTrigger(NonEmptyList.of(addon.nameAndVersion -> tt))

    def apply(addon: AddonArchive, tt: AddonTriggerType): MismatchingTrigger =
      MismatchingTrigger(NonEmptyList.of(addon.nameAndVersion -> tt))
  }
}
