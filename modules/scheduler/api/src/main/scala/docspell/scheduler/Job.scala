/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import cats.effect.Sync
import cats.syntax.functor._

import docspell.common._
import docspell.scheduler.usertask.UserTaskScope

import io.circe.Encoder

final case class Job[A](
    id: Ident,
    task: Ident,
    group: Ident,
    args: A,
    subject: String,
    submitter: Ident,
    priority: Priority,
    tracker: Option[Ident]
) {

  def encode(implicit E: Encoder[A]): Job[String] =
    Job(id, task, group, E.apply(args).noSpaces, subject, submitter, priority, tracker)
}

object Job {
  def createNew[F[_]: Sync, A](
      task: Ident,
      submitter: UserTaskScope,
      args: A,
      subject: String,
      priority: Priority,
      tracker: Option[Ident]
  ): F[Job[A]] =
    Ident.randomId[F].map { id =>
      val accId = submitter.toAccountId
      Job(id, task, accId.collective, args, subject, accId.user, priority, tracker)
    }
}
