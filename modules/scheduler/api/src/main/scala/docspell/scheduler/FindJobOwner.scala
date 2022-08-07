/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import cats.Applicative
import cats.data.{Kleisli, OptionT}

import docspell.common.AccountInfo

/** Strategy to find the user that submitted the job. This is used to emit events about
  * starting/finishing jobs.
  *
  * If an account cannot be determined, no events can be send.
  */
trait FindJobOwner[F[_]] { self =>
  def apply(job: Job[_]): F[Option[AccountInfo]]

  final def kleisli: Kleisli[OptionT[F, *], Job[_], AccountInfo] =
    Kleisli(job => OptionT(self(job)))
}

object FindJobOwner {

  def none[F[_]: Applicative]: FindJobOwner[F] =
    (_: Job[_]) => Applicative[F].pure(None)

  def of[F[_]](f: Job[_] => F[Option[AccountInfo]]): FindJobOwner[F] =
    (job: Job[_]) => f(job)
}
