/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.scheduler

import docspell.common.Ident

/** This is a mapping from some identifier to a task. This is used by the scheduler to
  * lookup an implementation using the taskName field of the RJob database record.
  */
final class JobTaskRegistry[F[_]](tasks: Map[Ident, JobTask[F]]) {

  def withTask(task: JobTask[F]): JobTaskRegistry[F] =
    JobTaskRegistry(tasks.updated(task.name, task))

  def find(taskName: Ident): Option[JobTask[F]] =
    tasks.get(taskName)
}

object JobTaskRegistry {

  def apply[F[_]](map: Map[Ident, JobTask[F]]): JobTaskRegistry[F] =
    new JobTaskRegistry[F](map)

  def empty[F[_]]: JobTaskRegistry[F] = apply(Map.empty)

}
