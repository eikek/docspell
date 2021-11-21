/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import cats.Applicative
import cats.implicits._

trait EventSink[F[_]] {

  /** Submit the event for asynchronous processing. */
  def offer(event: Event): F[Unit]
}

object EventSink {

  def apply[F[_]](run: Event => F[Unit]): EventSink[F] =
    (event: Event) => run(event)

  def silent[F[_]: Applicative]: EventSink[F] =
    EventSink(_ => ().pure[F])
}
