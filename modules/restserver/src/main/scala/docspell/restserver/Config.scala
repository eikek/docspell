package docspell.restserver

import docspell.backend.auth.Login
import docspell.backend.{Config => BackendConfig}
import docspell.common._

case class Config(
    appName: String,
    appId: Ident,
    baseUrl: LenientUri,
    bind: Config.Bind,
    backend: BackendConfig,
    auth: Login.Config
)

object Config {

  case class Bind(address: String, port: Int)
}
