/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.http4s

import cats.data.{Kleisli, OptionT}
import cats.effect.kernel.Async
import cats.implicits._

import docspell.common.Ident

import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.server.AuthMiddleware
import org.typelevel.ci._

// duplicated in joex project
object InternalHeader {

  private val headerName = ci"Docspell-Internal-Api"

  def header(value: String): Header.Raw =
    Header.Raw(headerName, value)

  def apply[F[_]: Async](key: Ident)(routes: HttpRoutes[F]): HttpRoutes[F] = {
    val dsl: Http4sDsl[F] = new Http4sDsl[F] {}
    import dsl._

    val authUser = checkSecret[F](key)

    val onFailure: AuthedRoutes[String, F] =
      Kleisli(req => OptionT.liftF(NotFound(req.context)))

    val middleware: AuthMiddleware[F, Unit] =
      AuthMiddleware(authUser, onFailure)

    middleware(AuthedRoutes(authReq => routes.run(authReq.req)))
  }

  private def checkSecret[F[_]: Async](
      key: Ident
  ): Kleisli[F, Request[F], Either[String, Unit]] =
    Kleisli(req =>
      extractSecret[F](req)
        .filter(compareSecret(key.id))
        .toRight("Secret invalid")
        .map(_ => ())
        .pure[F]
    )

  private def extractSecret[F[_]](req: Request[F]): Option[String] =
    req.headers.get(headerName).map(_.head.value)

  private def compareSecret(s1: String)(s2: String): Boolean =
    s1 == s2
}
