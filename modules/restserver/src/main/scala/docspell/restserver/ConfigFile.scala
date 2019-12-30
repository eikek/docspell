package docspell.restserver

import docspell.common.pureconfig.Implicits._
import docspell.backend.signup.{Config => SignupConfig}
import _root_.pureconfig._
import _root_.pureconfig.generic.auto._

object ConfigFile {
  import Implicits._

  def loadConfig: Config =
    ConfigSource.default.at("docspell.server").loadOrThrow[Config]

  object Implicits {
    implicit val signupModeReader: ConfigReader[SignupConfig.Mode] =
      ConfigReader[String].emap(reason(SignupConfig.Mode.fromString))
  }
}
