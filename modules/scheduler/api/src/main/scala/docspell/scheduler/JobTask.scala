/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import cats.effect.Sync
import cats.implicits._

import docspell.common.Ident
import docspell.common.syntax.all._

import io.circe.Decoder

/** Binds a Task to a name. This is required to lookup the code based on the taskName in
  * the RJob data and to execute it given the arguments that have to be read from a
  * string.
  *
  * Since the scheduler only has a string for the task argument, this only works for Task
  * impls that accept a string. There is a convenience constructor that uses circe to
  * decode json into some type A.
  */
case class JobTask[F[_]](
    name: Ident,
    task: Task[F, String, JobTaskResult],
    onCancel: Task[F, String, Unit]
)

object JobTask {

  def json[F[_]: Sync, A, B](
      name: Ident,
      task: Task[F, A, B],
      onCancel: Task[F, A, Unit]
  )(implicit
      D: Decoder[A],
      E: JobTaskResultEncoder[B]
  ): JobTask[F] = {
    val convert: String => F[A] =
      str =>
        str.parseJsonAs[A] match {
          case Right(a) => a.pure[F]
          case Left(ex) =>
            Sync[F].raiseError(new Exception(s"Cannot parse task arguments: $str", ex))
        }

    JobTask(name, task.contramap(convert).map(E.encode), onCancel.contramap(convert))
  }
}
