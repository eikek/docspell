/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.oidc

import org.http4s.HttpRoutes
import org.http4s.client.Client

object OpenidConnect {

  def codeFlow[F[_]](client: Client[F]): HttpRoutes[F] =
    ???
}
