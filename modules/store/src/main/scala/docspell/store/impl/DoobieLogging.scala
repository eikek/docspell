/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.impl

import cats.Applicative
import cats.syntax.all._

import docspell.logging.Logger
import docspell.store.impl.DoobieLogging.LogLabel

import doobie.util.log
import doobie.util.log.LogHandler

final class DoobieLogging[F[_]: Applicative](logger: Logger[F]) extends LogHandler[F] {
  override def run(logEvent: log.LogEvent): F[Unit] =
    if (LogLabel.fromEvent(logEvent).contains(LogLabel.Silent)) ().pure[F]
    else
      logEvent match {
        case log.Success(sql, args, _, exec, _) =>
          logger.trace(s"SQL: $sql  ($args) executed in $exec")

        case log.ProcessingFailure(sql, args, _, _, _, failure) =>
          logger.error(failure)(s"SQL processing failed: $sql ($args)")

        case log.ExecFailure(sql, args, _, _, failure) =>
          logger.error(failure)(s"SQL exec failed: $sql ($args)")
      }
}

object DoobieLogging {

  def apply[F[_]: Applicative](logger: Logger[F]): DoobieLogging[F] =
    new DoobieLogging[F](logger)

  sealed trait LogLabel extends Product {
    lazy val name: String = productPrefix.toLowerCase
  }
  object LogLabel {
    case object Silent extends LogLabel

    val all: List[LogLabel] = List(Silent)

    def fromString(str: String): Option[LogLabel] =
      all.find(_.name.equalsIgnoreCase(str))

    def fromEvent(e: log.LogEvent): Option[LogLabel] =
      fromString(e.label)
  }
}
