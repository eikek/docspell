/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.backend.signup
import docspell.common._

case class RegisterData(
    collName: Ident,
    login: Ident,
    password: Password,
    invite: Option[Ident]
)
