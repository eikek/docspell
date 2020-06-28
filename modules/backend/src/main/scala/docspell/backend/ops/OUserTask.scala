package docspell.backend.ops

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.store.queue.JobQueue
import docspell.store.usertask._

import io.circe.Encoder

trait OUserTask[F[_]] {

  /** Return the settings for all scan-mailbox tasks of the current user.
    */
  def getScanMailbox(account: AccountId): Stream[F, UserTask[ScanMailboxArgs]]

  /** Find a scan-mailbox task by the given id. */
  def findScanMailbox(
      id: Ident,
      account: AccountId
  ): OptionT[F, UserTask[ScanMailboxArgs]]

  /** Updates the scan-mailbox tasks and notifies the joex nodes.
    */
  def submitScanMailbox(
      account: AccountId,
      task: UserTask[ScanMailboxArgs]
  ): F[Unit]

  /** Return the settings for all the notify-due-items task of the
    * current user.
    */
  def getNotifyDueItems(account: AccountId): Stream[F, UserTask[NotifyDueItemsArgs]]

  /** Find a notify-due-items task by the given id. */
  def findNotifyDueItems(
      id: Ident,
      account: AccountId
  ): OptionT[F, UserTask[NotifyDueItemsArgs]]

  /** Updates the notify-due-items tasks and notifies the joex nodes.
    */
  def submitNotifyDueItems(
      account: AccountId,
      task: UserTask[NotifyDueItemsArgs]
  ): F[Unit]

  /** Removes a user task with the given id. */
  def deleteTask(account: AccountId, id: Ident): F[Unit]

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

      def getScanMailbox(account: AccountId): Stream[F, UserTask[ScanMailboxArgs]] =
        store
          .getByName[ScanMailboxArgs](account, ScanMailboxArgs.taskName)

      def findScanMailbox(
          id: Ident,
          account: AccountId
      ): OptionT[F, UserTask[ScanMailboxArgs]] =
        OptionT(getScanMailbox(account).find(_.id == id).compile.last)

      def deleteTask(account: AccountId, id: Ident): F[Unit] =
        (for {
          _ <- store.getByIdRaw(account, id)
          _ <- OptionT.liftF(store.deleteTask(account, id))
        } yield ()).getOrElse(())

      def submitScanMailbox(
          account: AccountId,
          task: UserTask[ScanMailboxArgs]
      ): F[Unit] =
        for {
          _ <- store.updateTask[ScanMailboxArgs](account, task)
          _ <- joex.notifyAllNodes
        } yield ()

      def getNotifyDueItems(account: AccountId): Stream[F, UserTask[NotifyDueItemsArgs]] =
        store
          .getByName[NotifyDueItemsArgs](account, NotifyDueItemsArgs.taskName)

      def findNotifyDueItems(
          id: Ident,
          account: AccountId
      ): OptionT[F, UserTask[NotifyDueItemsArgs]] =
        OptionT(getNotifyDueItems(account).find(_.id == id).compile.last)

      def submitNotifyDueItems(
          account: AccountId,
          task: UserTask[NotifyDueItemsArgs]
      ): F[Unit] =
        for {
          _ <- store.updateTask[NotifyDueItemsArgs](account, task)
          _ <- joex.notifyAllNodes
        } yield ()
    })

}
