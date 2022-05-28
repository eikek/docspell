/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store

import docspell.common.LenientUri

case class JdbcConfig(url: LenientUri, user: String, password: String) {

  val dbms: Db =
    JdbcConfig.extractDbmsName(url).fold(sys.error, identity)

  override def toString: String =
    s"JdbcConfig(${url.asString}, $user, ***)"
}

object JdbcConfig {
  private def extractDbmsName(jdbcUrl: LenientUri): Either[String, Db] =
    jdbcUrl.scheme.head match {
      case "jdbc" =>
        jdbcUrl.scheme.tail.headOption
          .map(Db.fromString)
          .getOrElse(Left(s"Invalid jdbc url: ${jdbcUrl.asString}"))
      case _ =>
        Left(s"No scheme provided for url: ${jdbcUrl.asString}")
    }
}
