/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.hk

import io.circe.Encoder
import io.circe.generic.semiauto.deriveEncoder

case class CleanupResult(removed: Int, disabled: Boolean) {
  def asString = if (disabled) "disabled" else s"$removed"
}
object CleanupResult {
  def of(n: Int): CleanupResult = CleanupResult(n, disabled = false)
  def disabled: CleanupResult = CleanupResult(0, disabled = true)

  implicit val jsonEncoder: Encoder[CleanupResult] =
    deriveEncoder
}
