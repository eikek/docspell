/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._

import docspell.backend.BackendApp
import docspell.backend.auth.ShareToken
import docspell.common.Logger
import docspell.restserver.Config

import org.http4s.HttpRoutes

object ShareSearchRoutes {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      cfg: Config,
      token: ShareToken
  ): HttpRoutes[F] = {
    val logger = Logger.log4s[F](org.log4s.getLogger)
    logger.trace(s"$backend $cfg $token")
    ???
  }
}
