/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.backend.signup

import docspell.common.Ident

sealed trait NewInviteResult { self: Product =>

  final def name: String =
    productPrefix.toLowerCase
}

object NewInviteResult {
  case class Success(id: Ident)  extends NewInviteResult
  case object InvitationDisabled extends NewInviteResult
  case object PasswordMismatch   extends NewInviteResult

  def passwordMismatch: NewInviteResult   = PasswordMismatch
  def invitationClosed: NewInviteResult   = InvitationDisabled
  def success(id: Ident): NewInviteResult = Success(id)
}
