/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.http4s

import cats.effect._

import docspell.joexapi.model.BasicResult

import org.http4s.Response
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

trait ThrowableResponseMapper {

  implicit class EitherThrowableOps[A](self: Either[Throwable, A]) {
    def rightAs[F[_]: Sync](f: A => F[Response[F]]): F[Response[F]] =
      self.fold(ThrowableResponseMapper.toResponse[F], f)

    def rightAs_[F[_]: Sync](r: => F[Response[F]]): F[Response[F]] =
      self.fold(ThrowableResponseMapper.toResponse[F], _ => r)
  }
}

object ThrowableResponseMapper {
  def toResponse[F[_]: Sync](ex: Throwable): F[Response[F]] =
    new Mapper[F].toResponse(ex)

  private class Mapper[F[_]: Sync] extends Http4sDsl[F] {
    def toResponse(ex: Throwable): F[Response[F]] =
      ex match {
        case _: IllegalArgumentException =>
          BadRequest(BasicResult(success = false, ex.getMessage))

        case _ =>
          InternalServerError(BasicResult(success = false, ex.getMessage))
      }
  }
}
