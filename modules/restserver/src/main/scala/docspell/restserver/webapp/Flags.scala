/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.webapp

import docspell.backend.signup.{Config => SignupConfig}
import docspell.common.{ByteSize, Ident, LenientUri}
import docspell.restserver.{BuildInfo, Config}

import io.circe._
import io.circe.generic.semiauto._
import yamusca.derive._
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
    showClassificationSettings: Boolean,
    downloadAllMaxFiles: Int,
    downloadAllMaxSize: ByteSize,
    uiVersion: Int,
    openIdAuth: List[Flags.OpenIdAuth],
    addonsEnabled: Boolean,
    oidcAutoRedirect: Boolean
)

object Flags {
  def apply(cfg: Config, uiVersion: Int): Flags =
    Flags(
      cfg.appName,
      getBaseUrl(cfg),
      cfg.backend.signup.mode,
      s"/app/assets/docspell-webapp/${BuildInfo.version}",
      cfg.integrationEndpoint.enabled,
      cfg.fullTextSearch.enabled,
      cfg.maxItemPageSize,
      cfg.maxNoteLength,
      cfg.showClassificationSettings,
      cfg.downloadAll.maxFiles,
      cfg.downloadAll.maxSize,
      uiVersion,
      cfg.openid
        .filter(_.enabled)
        .map(c => OpenIdAuth(c.provider.providerId, c.display, c.provider.logoutUrl)),
      cfg.backend.addons.enabled,
      cfg.oidcAutoRedirect && cfg.openIdSingleEnabled
    )

  final case class OpenIdAuth(
      provider: Ident,
      name: String,
      logoutUrl: Option[LenientUri]
  )

  object OpenIdAuth {
    implicit val jsonDecoder: Decoder[OpenIdAuth] =
      deriveDecoder[OpenIdAuth]

    implicit val jsonEncoder: Encoder[OpenIdAuth] =
      deriveEncoder[OpenIdAuth]
  }

  private def getBaseUrl(cfg: Config): String =
    if (cfg.baseUrl.isLocal) cfg.baseUrl.rootPathToEmpty.path.asString
    else cfg.baseUrl.rootPathToEmpty.asString

  implicit val jsonEncoder: Encoder[Flags] =
    deriveEncoder[Flags]

  implicit def yamuscaByteSizeConverter: ValueConverter[ByteSize] =
    ValueConverter.of(sz => Value.fromString(sz.bytes.toString))

  implicit def yamuscaIdentConverter: ValueConverter[Ident] =
    ValueConverter.of(id => Value.fromString(id.id))
  implicit def yamuscaOpenIdAuthConverter: ValueConverter[OpenIdAuth] =
    deriveValueConverter[OpenIdAuth]
  implicit def yamuscaSignupModeConverter: ValueConverter[SignupConfig.Mode] =
    ValueConverter.of(m => Value.fromString(m.name))
  implicit def yamuscaUriConverter: ValueConverter[LenientUri] =
    ValueConverter.of(uri => Value.fromString(uri.asString))
  implicit def yamuscaValueConverter: ValueConverter[Flags] =
    deriveValueConverter[Flags]
}
