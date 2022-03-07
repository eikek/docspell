/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect._
import cats.implicits._

import docspell.backend.JobFactory
import docspell.common.FileCopyTaskArgs
import docspell.store.queue.JobQueue
import docspell.store.records.RJob

trait OFileRepository[F[_]] {

  /** Inserts the job or return None if such a job already is running. */
  def cloneFileRepository(args: FileCopyTaskArgs, notifyJoex: Boolean): F[Option[RJob]]
}

object OFileRepository {

  def apply[F[_]: Async](
      queue: JobQueue[F],
      joex: OJoex[F]
  ): Resource[F, OFileRepository[F]] =
    Resource.pure(new OFileRepository[F] {
      def cloneFileRepository(
          args: FileCopyTaskArgs,
          notifyJoex: Boolean
      ): F[Option[RJob]] =
        for {
          job <- JobFactory.fileCopy(args)
          flag <- queue.insertIfNew(job)
          _ <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
        } yield Option.when(flag)(job)
    })
}
