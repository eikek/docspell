/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.ftssolr

final case class VersionDoc(id: String, currentVersion: Int)

object VersionDoc {

  object Fields {
    val id             = Field("id")
    val currentVersion = Field("current_version_i")
  }
}
