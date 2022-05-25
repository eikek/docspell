/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import cats.Id

import io.circe.Json

final private class CapturedLogger[F[_]] private (
    val data: LazyMap[String, Json],
    val delegate: Logger[F]
) extends Logger[F] {

  def log(ev: => LogEvent) =
    delegate.log(ev.copy(data = ev.data ++ data))

  def asUnsafe: Logger[Id] = {
    val self = delegate.asUnsafe
    new Logger[Id] {
      def log(ev: => LogEvent): Unit =
        self.log(ev.copy(data = ev.data ++ data))

      def asUnsafe = this
    }
  }
}

object CapturedLogger {

  def apply[F[_]](logger: Logger[F], data: LazyMap[String, Json]): Logger[F] =
    logger match {
      case cl: CapturedLogger[F] =>
        new CapturedLogger[F](cl.data ++ data, cl.delegate)
      case _ =>
        new CapturedLogger[F](data, logger)
    }
}
