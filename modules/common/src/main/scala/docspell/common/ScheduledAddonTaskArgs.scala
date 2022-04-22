/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

final case class ScheduledAddonTaskArgs(collective: Ident, addonTaskId: Ident)

object ScheduledAddonTaskArgs {
  val taskName: Ident = Ident.unsafe("addon-scheduled-task")

  implicit val jsonDecoder: Decoder[ScheduledAddonTaskArgs] = deriveDecoder
  implicit val jsonEncoder: Encoder[ScheduledAddonTaskArgs] = deriveEncoder
}
