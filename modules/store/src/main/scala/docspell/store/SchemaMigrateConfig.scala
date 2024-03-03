/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store

case class SchemaMigrateConfig(
    runMainMigrations: Boolean,
    runFixupMigrations: Boolean,
    repairSchema: Boolean
)

object SchemaMigrateConfig {
  val defaults = SchemaMigrateConfig(
    runMainMigrations = true,
    runFixupMigrations = true,
    repairSchema = false
  )
}
