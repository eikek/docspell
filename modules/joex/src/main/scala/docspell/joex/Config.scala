package docspell.joex

import docspell.store.JdbcConfig

case class Config(id: String
  , bind: Config.Bind
  , jdbc: JdbcConfig
)

object Config {


  val default: Config =
    Config("testid", Config.Bind("localhost", 7878), JdbcConfig("", "", ""))


  case class Bind(address: String, port: Int)
}
