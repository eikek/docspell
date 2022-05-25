/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.Monoid
import cats.syntax.all._

case class AddonExecutionResult(
    addonResults: List[AddonResult],
    pure: Boolean
) {
  def addonResult: AddonResult = addonResults.combineAll
  def isFailure: Boolean = addonResult.isFailure
  def isSuccess: Boolean = addonResult.isSuccess
}

object AddonExecutionResult {
  val empty: AddonExecutionResult =
    AddonExecutionResult(Nil, false)

  def combine(a: AddonExecutionResult, b: AddonExecutionResult): AddonExecutionResult =
    AddonExecutionResult(
      a.addonResults ::: b.addonResults,
      a.pure && b.pure
    )

  implicit val executionResultMonoid: Monoid[AddonExecutionResult] =
    Monoid.instance(empty, combine)
}
