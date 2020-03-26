package docspell.restserver

import docspell.backend.auth.Login
import docspell.backend.signup.{Config => SignupConfig}
import docspell.store.JdbcConfig
import docspell.backend.{Config => BackendConfig}
import docspell.common._
import scodec.bits.ByteVector

case class Config(
    appName: String,
    appId: Ident,
    baseUrl: LenientUri,
    bind: Config.Bind,
    backend: BackendConfig,
    auth: Login.Config
)

object Config {
  val postgres =
    JdbcConfig(
      LenientUri.unsafe("jdbc:postgresql://localhost:5432/docspelldev"),
      "dev",
      "dev"
    )
  val h2 = JdbcConfig(
    LenientUri.unsafe(
      "jdbc:h2:./target/docspelldev.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE"
    ),
    "sa",
    ""
  )

  val default: Config =
    Config(
      "Docspell",
      Ident.unsafe("restserver1"),
      LenientUri.unsafe("http://localhost:7880"),
      Config.Bind("localhost", 7880),
      BackendConfig(
        postgres,
        SignupConfig(SignupConfig.invite, Password("testpass"), Duration.hours(5 * 24)),
        BackendConfig.Files(512 * 1024, List(MimeType.pdf))
      ),
      Login.Config(ByteVector.fromValidHex("caffee"), Duration.minutes(2))
    )

  case class Bind(address: String, port: Int)
}
