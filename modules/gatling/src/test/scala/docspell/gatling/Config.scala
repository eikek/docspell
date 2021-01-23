package docspell.gatling

import pureconfig.ConfigSource
import pureconfig.generic.auto._

case class Config(baseUrl: String)

object Config {

  lazy val loaded: Config =
    ConfigSource.default.at("docspell.gatling").loadOrThrow[Config]
}
