/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons.runner

import cats.Applicative
import cats.effect.{Ref, Sync}
import cats.syntax.all._
import fs2.Pipe

trait CollectOut[F[_]] {

  def get: F[String]

  def append: Pipe[F, String, String]
}

object CollectOut {

  def none[F[_]: Applicative]: CollectOut[F] =
    new CollectOut[F] {
      def get = "".pure[F]
      def append = identity
    }

  def buffer[F[_]: Sync]: F[CollectOut[F]] =
    Ref
      .of[F, Vector[String]](Vector.empty)
      .map(buffer =>
        new CollectOut[F] {
          override def get =
            buffer.get.map(_.mkString("\n").trim)

          override def append =
            _.evalTap(line =>
              if (line.trim.nonEmpty) buffer.update(_.appended(line)) else ().pure[F]
            )
        }
      )
}
