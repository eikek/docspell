package docspell.backend.ops

import cats.implicits._
import cats.effect._
import com.github.eikek.calev.CalEvent
import io.circe.Encoder

import docspell.store.queue.JobQueue
import docspell.store.usertask._
import docspell.common._

trait OUserTask[F[_]] {

  /** Return the settings for the notify-due-items task of the current
    * user. There is at most one such task per user.
    */
  def getNotifyDueItems(account: AccountId): F[UserTask[NotifyDueItemsArgs]]

  /** Updates the notify-due-items tasks and notifies the joex nodes.
    */
  def submitNotifyDueItems(
      account: AccountId,
      task: UserTask[NotifyDueItemsArgs]
  ): F[Unit]

  /** Discards the schedule and immediately submits the task to the job
    * executor's queue. It will not update the corresponding periodic
    * task.
    */
  def executeNow[A](account: AccountId, task: UserTask[A])(implicit
      E: Encoder[A]
  ): F[Unit]
}

object OUserTask {

  def apply[F[_]: Effect](
      store: UserTaskStore[F],
      queue: JobQueue[F],
      joex: OJoex[F]
  ): Resource[F, OUserTask[F]] =
    Resource.pure[F, OUserTask[F]](new OUserTask[F] {

      def executeNow[A](account: AccountId, task: UserTask[A])(implicit
          E: Encoder[A]
      ): F[Unit] =
        for {
          ptask <- task.encode.toPeriodicTask(account)
          job   <- ptask.toJob
          _     <- queue.insert(job)
          _     <- joex.notifyAllNodes
        } yield ()

      def getNotifyDueItems(account: AccountId): F[UserTask[NotifyDueItemsArgs]] =
        store
          .getOneByName[NotifyDueItemsArgs](account, NotifyDueItemsArgs.taskName)
          .getOrElseF(notifyDueItemsDefault(account))

      def submitNotifyDueItems(
          account: AccountId,
          task: UserTask[NotifyDueItemsArgs]
      ): F[Unit] =
        for {
          _ <- store.updateOneTask[NotifyDueItemsArgs](account, task)
          _ <- joex.notifyAllNodes
        } yield ()

      private def notifyDueItemsDefault(
          account: AccountId
      ): F[UserTask[NotifyDueItemsArgs]] =
        for {
          id <- Ident.randomId[F]
        } yield UserTask(
          id,
          NotifyDueItemsArgs.taskName,
          false,
          CalEvent.unsafe("*-*-1/7 12:00"),
          NotifyDueItemsArgs(
            account,
            Ident.unsafe(""),
            Nil,
            None,
            5,
            None,
            Nil,
            Nil
          )
        )
    })

}
