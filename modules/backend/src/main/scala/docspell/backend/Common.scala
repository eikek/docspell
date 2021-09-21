/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend

import cats.effect._

import org.mindrot.jbcrypt.BCrypt

object Common {

  def genSaltString[F[_]: Sync]: F[String] =
    Sync[F].delay(BCrypt.gensalt())
}
