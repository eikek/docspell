/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend

import docspell.common.Password

import org.mindrot.jbcrypt.BCrypt

object PasswordCrypt {

  def crypt(pass: Password): Password =
    Password(BCrypt.hashpw(pass.pass, BCrypt.gensalt()))

  def check(plain: Password, hashed: Password): Boolean =
    BCrypt.checkpw(plain.pass, hashed.pass)
}
