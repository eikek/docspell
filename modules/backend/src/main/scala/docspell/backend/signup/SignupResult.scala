/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.signup

import docspell.store.AddResult

sealed trait SignupResult {}

object SignupResult {

  case object CollectiveExists extends SignupResult
  case object InvalidInvitationKey extends SignupResult
  case object SignupClosed extends SignupResult
  case class Failure(ex: Throwable) extends SignupResult
  case object Success extends SignupResult

  def collectiveExists: SignupResult = CollectiveExists
  def invalidInvitationKey: SignupResult = InvalidInvitationKey
  def signupClosed: SignupResult = SignupClosed
  def failure(ex: Throwable): SignupResult = Failure(ex)
  def success: SignupResult = Success

  def fromAddResult(ar: AddResult): SignupResult =
    ar match {
      case AddResult.Success         => Success
      case AddResult.Failure(ex)     => Failure(ex)
      case AddResult.EntityExists(_) => CollectiveExists
    }
}
