package docspell.joex

import docspell.common.config.Implicits._
import docspell.joex.scheduler.CountingScheme

import pureconfig._
import pureconfig.generic.auto._

object ConfigFile {
  import Implicits._

  def loadConfig: Config =
    ConfigSource.default.at("docspell.joex").loadOrThrow[Config]

  object Implicits {
    implicit val countingSchemeReader: ConfigReader[CountingScheme] =
      ConfigReader[String].emap(reason(CountingScheme.readString))

  }
}
