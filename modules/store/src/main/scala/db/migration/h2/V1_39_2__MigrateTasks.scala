/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.h2

import cats.effect.unsafe.implicits._

import db.migration.common.MigrateCollectiveIdTaskArgs
import org.flywaydb.core.api.migration.{BaseJavaMigration, Context}

class V1_39_2__MigrateTasks extends BaseJavaMigration {
  val logger = org.log4s.getLogger

  override def migrate(ctx: Context): Unit =
    MigrateCollectiveIdTaskArgs.run(ctx).unsafeRunSync()
}
