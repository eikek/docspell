/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

/** A marker trait for task arguments.
  *
  * Arguments for tasks are stored as a JSON blob in the database. Changes in structure
  * requires a corresponding database migration.
  */
trait TaskArguments
