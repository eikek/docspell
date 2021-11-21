/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend

import docspell.backend.signup.{Config => SignupConfig}
import docspell.common._
import docspell.store.JdbcConfig

import emil.javamail.Settings

case class Config(
    mailDebug: Boolean,
    jdbc: JdbcConfig,
    signup: SignupConfig,
    files: Config.Files
) {

  def mailSettings: Settings =
    Settings.defaultSettings.copy(debug = mailDebug)
}

object Config {

  case class Files(chunkSize: Int, validMimeTypes: Seq[MimeType])

}
