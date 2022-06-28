/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.ws

import cats.effect._
import cats.syntax.all._
import fs2.concurrent.Topic

import docspell.logging.Logger

/** Asynchronous operations that run on the rest-server can communicate their results via
  * websocket.
  */
object Background {
  // TODO avoid resubmitting same stuff

  def apply[F[_]: Async, A](
      wsTopic: Topic[F, OutputEvent],
      logger: Option[Logger[F]] = None
  )(run: F[A])(implicit enc: OutputEventEncoder[A]): F[Unit] = {
    val log = logger.getOrElse(docspell.logging.getLogger[F])
    Async[F]
      .start {
        run.map(enc.encode).attempt.flatMap {
          case Right(ev) =>
            log.info(s"Sending response from async operation: $ev") *>
              wsTopic.publish1(ev).void
          case Left(ex) =>
            log.warn(ex)(s"Background operation failed!")
        }
      }
      .as(())
  }
}
