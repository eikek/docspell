package docspell.scheduler

import docspell.scheduler.usertask.UserTaskStore

trait JobStoreModule[F[_]] {

  def userTasks: UserTaskStore[F]
  def jobs: JobStore[F]
}
