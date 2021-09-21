/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.signup
import docspell.common._

case class RegisterData(
    collName: Ident,
    login: Ident,
    password: Password,
    invite: Option[Ident]
)
