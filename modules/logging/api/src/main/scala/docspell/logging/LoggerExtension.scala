/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import cats.Applicative
import fs2.Stream

trait LoggerExtension[F[_]] { self: Logger[F] =>

  def stream: Logger[Stream[F, *]] =
    new Logger[Stream[F, *]] {
      def log(ev: => LogEvent) =
        Stream.eval(self.log(ev))

      def asUnsafe = self.asUnsafe
    }

  def andThen(other: Logger[F])(implicit F: Applicative[F]): Logger[F] =
    AndThenLogger.combine(self, other)

  def >>(other: Logger[F])(implicit F: Applicative[F]): Logger[F] =
    AndThenLogger.combine(self, other)
}
