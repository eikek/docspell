package docspell.restserver.webapp

import docspell.backend.signup.{Config => SignupConfig}
import docspell.common.LenientUri
import docspell.restserver.{BuildInfo, Config}

import io.circe._
import io.circe.generic.semiauto._
import yamusca.implicits._
import yamusca.imports._

case class Flags(
    appName: String,
    baseUrl: String,
    signupMode: SignupConfig.Mode,
    docspellAssetPath: String,
    integrationEnabled: Boolean,
    fullTextSearchEnabled: Boolean,
    maxPageSize: Int,
    maxNoteLength: Int,
    showClassificationSettings: Boolean
)

object Flags {
  def apply(cfg: Config): Flags =
    Flags(
      cfg.appName,
      getBaseUrl(cfg),
      cfg.backend.signup.mode,
      s"/app/assets/docspell-webapp/${BuildInfo.version}",
      cfg.integrationEndpoint.enabled,
      cfg.fullTextSearch.enabled,
      cfg.maxItemPageSize,
      cfg.maxNoteLength,
      cfg.showClassificationSettings
    )

  private def getBaseUrl(cfg: Config): String =
    if (cfg.baseUrl.isLocal) cfg.baseUrl.rootPathToEmpty.path.asString
    else cfg.baseUrl.rootPathToEmpty.asString

  implicit val jsonEncoder: Encoder[Flags] =
    deriveEncoder[Flags]

  implicit def yamuscaSignupModeConverter: ValueConverter[SignupConfig.Mode] =
    ValueConverter.of(m => Value.fromString(m.name))
  implicit def yamuscaUriConverter: ValueConverter[LenientUri] =
    ValueConverter.of(uri => Value.fromString(uri.asString))
  implicit def yamuscaValueConverter: ValueConverter[Flags] =
    ValueConverter.deriveConverter[Flags]
}
