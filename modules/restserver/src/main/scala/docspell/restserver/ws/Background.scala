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
      .background(run)
      .use(
        _.flatMap(
          _.fold(
            log.warn("The background operation has been cancelled!"),
            ex => log.error(ex)("Error running background operation!"),
            event =>
              event
                .map(enc.encode)
                .flatTap(ev => log.info(s"Sending response from async operation: $ev"))
                .flatMap(wsTopic.publish1)
                .void
          )
        )
      )
  }
}
