/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import cats.effect._
import fs2.concurrent.SignallingRef

import docspell.pubsub.api.PubSubT
import docspell.scheduler._

object PeriodicSchedulerBuilder {

  def resource[F[_]: Async](
      cfg: PeriodicSchedulerConfig,
      store: PeriodicTaskStore[F],
      pubsub: PubSubT[F]
  ): Resource[F, PeriodicScheduler[F]] =
    for {
      waiter <- Resource.eval(SignallingRef(true))
      state <- Resource.eval(SignallingRef(PeriodicSchedulerImpl.emptyState[F]))
      psch = new PeriodicSchedulerImpl[F](
        cfg,
        store,
        pubsub,
        waiter,
        state
      )
      _ <- Resource.eval(psch.init)
    } yield psch
}
