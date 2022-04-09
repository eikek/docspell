/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import docspell.common.Ident

trait JobStore[F[_]] {

  /** Inserts the job into the queue to get picked up as soon as possible. The job must
    * have a new unique id.
    */
  def insert(job: Job[String]): F[Unit]

  /** Inserts the job into the queue only, if there is no job with the same tracker-id
    * running at the moment. The job id must be a new unique id.
    *
    * If the job has no tracker defined, it is simply inserted. It returns `true` if the
    * job was inserted.
    */
  def insertIfNew(job: Job[String]): F[Boolean]

  def insertAll(jobs: Seq[Job[String]]): F[List[Boolean]]

  def insertAllIfNew(jobs: Seq[Job[String]]): F[List[Boolean]]

  def findById(jobId: Ident): F[Option[Job[String]]]
}
