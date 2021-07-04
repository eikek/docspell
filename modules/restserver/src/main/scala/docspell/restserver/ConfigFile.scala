/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.restserver

import docspell.backend.signup.{Config => SignupConfig}
import docspell.common.config.Implicits._

import pureconfig._
import pureconfig.generic.auto._

object ConfigFile {
  import Implicits._

  def loadConfig: Config =
    ConfigSource.default.at("docspell.server").loadOrThrow[Config]

  object Implicits {
    implicit val signupModeReader: ConfigReader[SignupConfig.Mode] =
      ConfigReader[String].emap(reason(SignupConfig.Mode.fromString))
  }
}
