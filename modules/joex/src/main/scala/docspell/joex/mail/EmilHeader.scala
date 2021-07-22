/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.mail

import emil.builder._

object EmilHeader {

  // Remove with next emil version
  def optionalHeader[F[_]](name: String, value: Option[String]): Trans[F] =
    value.map(v => CustomHeader[F](name, v)).getOrElse(Trans[F](identity))

  def listId[F[_]](listId: String): Trans[F] =
    optionalHeader("List-Id", Option(listId).filter(_.nonEmpty))

}
