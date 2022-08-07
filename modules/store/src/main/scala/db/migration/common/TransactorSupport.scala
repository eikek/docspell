/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.common

import cats.effect.IO

import docspell.logging.Logger

import doobie.util.transactor.{Strategy, Transactor}
import org.flywaydb.core.api.migration.Context

trait TransactorSupport {

  def logger: Logger[IO]

  def mkTransactor(ctx: Context): Transactor[IO] = {
    val xa = Transactor.fromConnection[IO](ctx.getConnection)
    logger.asUnsafe.info(s"Creating transactor for db migrations from connection: $xa")
    Transactor.strategy.set(xa, Strategy.void) // transactions are handled by flyway
  }
}
