/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.backend

import cats.effect._

import org.mindrot.jbcrypt.BCrypt

object Common {

  def genSaltString[F[_]: Sync]: F[String] =
    Sync[F].delay(BCrypt.gensalt())
}
