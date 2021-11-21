/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import cats.data.Kleisli
import fs2.Stream

trait EventReader[F[_]] {

  /** Stream to allow processing of events offered via a `EventSink` */
  def consume(maxConcurrent: Int)(run: Kleisli[F, Event, Unit]): Stream[F, Nothing]

}
