/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.oidc

import docspell.common._

import org.http4s.Request

trait CodeFlowConfig[F[_]] {

  /** Return the URL to the path where the `CodeFlowRoutes` are mounted. This is used to
    * construct the redirect url.
    */
  def getEndpointUrl(req: Request[F]): LenientUri

  /** Multiple authentication providers are supported, each has its own id. For a given
    * id, return the config to use.
    */
  def findProvider(id: Ident): Option[ProviderConfig]

}

object CodeFlowConfig {

  def apply[F[_]](
      url: Request[F] => LenientUri,
      provider: Ident => Option[ProviderConfig]
  ): CodeFlowConfig[F] =
    new CodeFlowConfig[F] {
      def getEndpointUrl(req: Request[F]): LenientUri     = url(req)
      def findProvider(id: Ident): Option[ProviderConfig] = provider(id)
    }

  private[oidc] def resumeUri[F[_]](
      req: Request[F],
      prov: ProviderConfig,
      cfg: CodeFlowConfig[F]
  ): LenientUri =
    cfg.getEndpointUrl(req) / prov.providerId.id / "resume"

}
