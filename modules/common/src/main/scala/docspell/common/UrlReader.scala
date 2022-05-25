/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.ApplicativeError
import cats.effect._
import fs2.Stream

trait UrlReader[F[_]] {
  def apply(url: LenientUri): Stream[F, Byte]
}

object UrlReader {

  def instance[F[_]](f: LenientUri => Stream[F, Byte]): UrlReader[F] =
    (url: LenientUri) => f(url)

  def failWith[F[_]](
      message: String
  )(implicit F: ApplicativeError[F, Throwable]): UrlReader[F] =
    instance(url =>
      Stream.raiseError(
        new IllegalStateException(s"Unable to read '${url.asString}': $message")
      )
    )

  def apply[F[_]](implicit r: UrlReader[F]): UrlReader[F] = r

  implicit def defaultReader[F[_]: Sync]: UrlReader[F] =
    instance(_.readURL[F](8192))
}
