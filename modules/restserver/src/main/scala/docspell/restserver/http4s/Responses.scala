/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.http4s

import cats.data.NonEmptyList
import cats.data.OptionT
import cats.effect.Sync
import fs2.text.utf8
import fs2.{Pure, Stream}

import org.http4s._
import org.http4s.headers._

object Responses {

  private[this] val pureForbidden: Response[Pure] =
    Response(
      Status.Forbidden,
      body = Stream("Forbidden").through(utf8.encode),
      headers = Headers(`Content-Type`(MediaType.text.plain, Charset.`UTF-8`) :: Nil)
    )

  private[this] val pureUnauthorized: Response[Pure] =
    Response(
      Status.Unauthorized,
      body = Stream("Unauthorized").through(utf8.encode),
      headers = Headers(`Content-Type`(MediaType.text.plain, Charset.`UTF-8`) :: Nil)
    )

  def forbidden[F[_]]: Response[F] =
    pureForbidden.covary[F].copy(body = pureForbidden.body.covary[F])

  def unauthorized[F[_]]: Response[F] =
    pureUnauthorized.covary[F].copy(body = pureUnauthorized.body.covary[F])

  def noCache[F[_]](r: Response[F]): Response[F] =
    r.withHeaders(
      `Cache-Control`(
        NonEmptyList.of(CacheDirective.`no-cache`(), CacheDirective.`private`())
      )
    )

  def notFoundRoute[F[_]: Sync]: HttpRoutes[F] =
    HttpRoutes(_ => OptionT.pure(Response.notFound[F]))

  def notFoundRoute[F[_]: Sync, A](body: A)(implicit
      entityEncoder: EntityEncoder[F, A]
  ): HttpRoutes[F] =
    HttpRoutes(_ => OptionT.pure(Response.notFound[F].withEntity(body)))
}
