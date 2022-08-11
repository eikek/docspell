/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.mariadb

import cats.effect.unsafe.implicits._

import db.migration.common.MigrateNotifyTasks
import org.flywaydb.core.api.migration.BaseJavaMigration
import org.flywaydb.core.api.migration.Context

class V1_29_2__MigrateNotifyTask extends BaseJavaMigration {
  val logger = org.log4s.getLogger

  override def migrate(ctx: Context): Unit =
    MigrateNotifyTasks.run(ctx).unsafeRunSync()
}
