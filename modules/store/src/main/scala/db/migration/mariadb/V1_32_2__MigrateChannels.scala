/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.mariadb

import cats.effect.unsafe.implicits._

import db.migration.common.MigrateDueItemTasks
import org.flywaydb.core.api.migration.{BaseJavaMigration, Context}

class V1_32_2__MigrateChannels extends BaseJavaMigration {
  val logger = org.log4s.getLogger

  override def migrate(ctx: Context): Unit =
    MigrateDueItemTasks.run(ctx).unsafeRunSync()

}
