/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend

import docspell.common.Password

import org.mindrot.jbcrypt.BCrypt

object PasswordCrypt {
  // BCrypt requires non-empty strings

  def crypt(pass: Password): Password =
    if (pass.isEmpty) sys.error("Empty password given to hash")
    else Password(BCrypt.hashpw(pass.pass, BCrypt.gensalt()))

  def check(plain: Password, hashed: Password): Boolean =
    if (plain.isEmpty || hashed.isEmpty) false
    else BCrypt.checkpw(plain.pass, hashed.pass)
}
