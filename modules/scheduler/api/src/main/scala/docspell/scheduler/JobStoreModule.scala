/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import docspell.scheduler.usertask.UserTaskStore

trait JobStoreModule[F[_]] {

  def userTasks: UserTaskStore[F]
  def jobs: JobStore[F]
}
