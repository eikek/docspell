package docspell.joex

import docspell.common.pureconfig.Implicits._
import _root_.pureconfig._
import _root_.pureconfig.generic.auto._
import docspell.joex.scheduler.CountingScheme

object ConfigFile {
  import Implicits._

  def loadConfig: Config =
    ConfigSource.default.at("docspell.joex").loadOrThrow[Config]

  object Implicits {
    implicit val countingSchemeReader: ConfigReader[CountingScheme] =
      ConfigReader[String].emap(reason(CountingScheme.readString))

  }
}
