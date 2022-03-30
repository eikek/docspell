/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import docspell.backend.auth.Login
import docspell.backend.{Config => BackendConfig}
import docspell.common._
import docspell.config.{FtsType, PgFtsConfig}
import docspell.ftssolr.SolrConfig
import docspell.logging.LogConfig
import docspell.oidc.ProviderConfig
import docspell.pubsub.naive.PubSubConfig
import docspell.restserver.Config.{OpenIdConfig, ServerOptions}
import docspell.restserver.auth.OpenId
import docspell.restserver.http4s.InternalHeader

import com.comcast.ip4s.IpAddress

case class Config(
    appName: String,
    appId: Ident,
    baseUrl: LenientUri,
    internalUrl: LenientUri,
    logging: LogConfig,
    bind: Config.Bind,
    serverOptions: ServerOptions,
    backend: BackendConfig,
    auth: Login.Config,
    showClassificationSettings: Boolean,
    integrationEndpoint: Config.IntegrationEndpoint,
    maxItemPageSize: Int,
    maxNoteLength: Int,
    fullTextSearch: Config.FullTextSearch,
    adminEndpoint: Config.AdminEndpoint,
    openid: List[OpenIdConfig]
) {
  def openIdEnabled: Boolean =
    openid.exists(_.enabled)

  def pubSubConfig(headerValue: Ident): PubSubConfig =
    PubSubConfig(
      appId,
      internalUrl / "internal" / "pubsub",
      100,
      InternalHeader.header(headerValue.id)
    )
}

object Config {

  case class ServerOptions(
      responseTimeout: Duration,
      enableHttp2: Boolean,
      maxConnections: Int
  )
  case class Bind(address: String, port: Int)

  case class AdminEndpoint(secret: String)

  case class IntegrationEndpoint(
      enabled: Boolean,
      priority: Priority,
      sourceName: String,
      allowedIps: IntegrationEndpoint.AllowedIps,
      httpBasic: IntegrationEndpoint.HttpBasic,
      httpHeader: IntegrationEndpoint.HttpHeader
  )

  object IntegrationEndpoint {
    case class HttpBasic(enabled: Boolean, realm: String, user: String, password: String)
    case class HttpHeader(enabled: Boolean, headerName: String, headerValue: String)
    case class AllowedIps(enabled: Boolean, ips: Set[String]) {

      def containsAddress(ipa: IpAddress): Boolean = {
        val inet = ipa.toInetAddress
        val ip = inet.getHostAddress
        lazy val ipParts = ip.split('.')

        def checkSingle(pattern: String): Boolean =
          pattern == ip || (inet.isLoopbackAddress && pattern == "127.0.0.1") || pattern
            .split('.')
            .zip(ipParts)
            .foldLeft(true) { case (r, (a, b)) =>
              r && (a == "*" || a == b)
            }

        ips.exists(checkSingle)
      }
    }
  }

  case class FullTextSearch(
      enabled: Boolean,
      backend: FtsType,
      solr: SolrConfig,
      postgresql: PgFtsConfig
  ) {

    def info: String =
      if (!enabled) "Disabled."
      else
        backend match {
          case FtsType.Solr =>
            s"Solr(${solr.url.asString})"
          case FtsType.PostgreSQL =>
            if (postgresql.useDefaultConnection)
              "PostgreSQL(default)"
            else
              s"PostgreSQL(${postgresql.jdbc.url.asString})"
        }
  }

  object FullTextSearch {}

  final case class OpenIdConfig(
      enabled: Boolean,
      display: String,
      collectiveKey: OpenId.UserInfo.Extractor,
      userKey: String,
      provider: ProviderConfig
  )

}
