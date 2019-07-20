package docspell.restserver

import docspell.store.JdbcConfig

case class Config(appName: String
  , baseUrl: String
  , bind: Config.Bind
  , jdbc: JdbcConfig
)

object Config {


  val default: Config =
    Config("Docspell", "http://localhost:7880", Config.Bind("localhost", 7880), JdbcConfig("", "", ""))


  case class Bind(address: String, port: Int)
}
