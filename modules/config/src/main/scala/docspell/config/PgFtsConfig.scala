/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.config

import docspell.common._
import docspell.ftspsql._
import docspell.store.JdbcConfig

case class PgFtsConfig(
    useDefaultConnection: Boolean,
    jdbc: JdbcConfig,
    pgQueryParser: PgQueryParser,
    pgRankNormalization: RankNormalization,
    pgConfig: Map[Language, String]
) {

  def toPsqlConfig(stdConn: JdbcConfig): PsqlConfig = {
    val db =
      if (useDefaultConnection) stdConn
      else jdbc

    PsqlConfig(
      db.url,
      db.user,
      Password(db.password),
      pgConfig,
      pgQueryParser,
      pgRankNormalization
    )
  }
}

object PgFtsConfig {}
