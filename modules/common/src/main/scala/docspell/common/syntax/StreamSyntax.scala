/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.syntax

import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import io.circe._
import io.circe.parser._

trait StreamSyntax {
  implicit class StringStreamOps[F[_]](s: Stream[F, String]) {
    def parseJsonAs[A](implicit d: Decoder[A], F: Sync[F]): F[Either[Throwable, A]] =
      s.compile.string
        .map(str =>
          for {
            json <- parse(str).leftMap(_.underlying)
            value <- json.as[A]
          } yield value
        )
  }
}
