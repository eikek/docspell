/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.mariadb

import cats.effect.unsafe.implicits._

import db.migration.MigrationTasks
import doobie.implicits._
import org.flywaydb.core.api.migration.{BaseJavaMigration, Context}

class V1_32_2__MigrateChannels extends BaseJavaMigration with MigrationTasks {
  val logger = org.log4s.getLogger

  override def migrate(ctx: Context): Unit = {
    val xa = mkTransactor(ctx)
    migratePeriodicItemTasks.transact(xa).unsafeRunSync()
  }
}
