/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import cats.data.NonEmptyList
import fs2.Stream

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records.{RJob, RJobLog}

import doobie.ConnectionIO

object QJobQueue {

  def queueStateSnapshot(
      collective: Ident,
      max: Long
  ): Stream[ConnectionIO, (RJob, Vector[RJobLog])] = {
    val JC = RJob.T
    val waiting = NonEmptyList.of(JobState.Waiting, JobState.Stuck, JobState.Scheduled)
    val running = NonEmptyList.of(JobState.Running)
    // val done                   = JobState.all.filterNot(js => ).diff(waiting).diff(running)

    def selectJobs(now: Timestamp): Stream[ConnectionIO, RJob] = {
      val refDate = now.minusHours(24)
      val runningJobs = Select(
        select(JC.all),
        from(JC),
        JC.group === collective && JC.state.in(running)
      ).orderBy(JC.submitted.desc).build.query[RJob].stream

      val waitingJobs = Select(
        select(JC.all),
        from(JC),
        JC.group === collective && JC.state.in(waiting) && JC.submitted > refDate
      ).orderBy(JC.submitted.desc).build.query[RJob].stream.take(max)

      val doneJobs = Select(
        select(JC.all),
        from(JC),
        and(
          JC.group === collective,
          JC.state.in(JobState.done),
          JC.submitted > refDate
        )
      ).orderBy(JC.submitted.desc).build.query[RJob].stream.take(max)

      runningJobs ++ waitingJobs ++ doneJobs
    }

    def selectLogs(job: RJob): ConnectionIO[Vector[RJobLog]] =
      RJobLog.findLogs(job.id)

    for {
      now <- Stream.eval(Timestamp.current[ConnectionIO])
      job <- selectJobs(now)
      res <- Stream.eval(selectLogs(job))
    } yield (job, res)
  }
}
