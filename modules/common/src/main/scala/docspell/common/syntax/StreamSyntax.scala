/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.syntax

import cats.effect.Sync
import cats.implicits._
import fs2.Stream
import fs2.hashing.{HashAlgorithm, Hashing}

import io.circe._
import io.circe.parser._
import scodec.bits.ByteVector

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

  implicit final class ByteStreamSyntax[F[_]](self: Stream[F, Byte]) {
    def sha256Hex(implicit F: Sync[F]): F[String] =
      self
        .through(Hashing.forSync[F].hash(HashAlgorithm.SHA256))
        .map(_.bytes)
        .compile
        .fold(ByteVector.empty)(_ ++ _.toByteVector)
        .map(_.toHex)
  }
}
object StreamSyntax extends StreamSyntax
