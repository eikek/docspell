/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.http4s

import cats.Functor

import docspell.common._

import org.http4s._

object EnvMiddleware {

  def apply[F[_]: Functor](in: HttpRoutes[F]): HttpRoutes[F] =
    NoCacheMiddleware.route(EnvMode.current.isDev)(in)
}
