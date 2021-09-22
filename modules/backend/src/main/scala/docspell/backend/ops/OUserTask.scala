/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

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

  /** Return the settings for all scan-mailbox tasks of the current user. */
  def getScanMailbox(scope: UserTaskScope): Stream[F, UserTask[ScanMailboxArgs]]

  /** Find a scan-mailbox task by the given id. */
  def findScanMailbox(
      id: Ident,
      scope: UserTaskScope
  ): OptionT[F, UserTask[ScanMailboxArgs]]

  /** Updates the scan-mailbox tasks and notifies the joex nodes. */
  def submitScanMailbox(
      scope: UserTaskScope,
      subject: Option[String],
      task: UserTask[ScanMailboxArgs]
  ): F[Unit]

  /** Return the settings for all the notify-due-items task of the current user. */
  def getNotifyDueItems(scope: UserTaskScope): Stream[F, UserTask[NotifyDueItemsArgs]]

  /** Find a notify-due-items task by the given id. */
  def findNotifyDueItems(
      id: Ident,
      scope: UserTaskScope
  ): OptionT[F, UserTask[NotifyDueItemsArgs]]

  /** Updates the notify-due-items tasks and notifies the joex nodes. */
  def submitNotifyDueItems(
      scope: UserTaskScope,
      subject: Option[String],
      task: UserTask[NotifyDueItemsArgs]
  ): F[Unit]

  /** Removes a user task with the given id. */
  def deleteTask(scope: UserTaskScope, id: Ident): F[Unit]

  /** Discards the schedule and immediately submits the task to the job executor's queue.
    * It will not update the corresponding periodic task.
    */
  def executeNow[A](scope: UserTaskScope, subject: Option[String], task: UserTask[A])(
      implicit E: Encoder[A]
  ): F[Unit]
}

object OUserTask {

  def apply[F[_]: Async](
      store: UserTaskStore[F],
      queue: JobQueue[F],
      joex: OJoex[F]
  ): Resource[F, OUserTask[F]] =
    Resource.pure[F, OUserTask[F]](new OUserTask[F] {

      def executeNow[A](scope: UserTaskScope, subject: Option[String], task: UserTask[A])(
          implicit E: Encoder[A]
      ): F[Unit] =
        for {
          ptask <- task.encode.toPeriodicTask(scope, subject)
          job <- ptask.toJob
          _ <- queue.insert(job)
          _ <- joex.notifyAllNodes
        } yield ()

      def getScanMailbox(scope: UserTaskScope): Stream[F, UserTask[ScanMailboxArgs]] =
        store
          .getByName[ScanMailboxArgs](scope, ScanMailboxArgs.taskName)

      def findScanMailbox(
          id: Ident,
          scope: UserTaskScope
      ): OptionT[F, UserTask[ScanMailboxArgs]] =
        OptionT(getScanMailbox(scope).find(_.id == id).compile.last)

      def deleteTask(scope: UserTaskScope, id: Ident): F[Unit] =
        (for {
          _ <- store.getByIdRaw(scope, id)
          _ <- OptionT.liftF(store.deleteTask(scope, id))
        } yield ()).getOrElse(())

      def submitScanMailbox(
          scope: UserTaskScope,
          subject: Option[String],
          task: UserTask[ScanMailboxArgs]
      ): F[Unit] =
        for {
          _ <- store.updateTask[ScanMailboxArgs](scope, subject, task)
          _ <- joex.notifyAllNodes
        } yield ()

      def getNotifyDueItems(
          scope: UserTaskScope
      ): Stream[F, UserTask[NotifyDueItemsArgs]] =
        store
          .getByName[NotifyDueItemsArgs](scope, NotifyDueItemsArgs.taskName)

      def findNotifyDueItems(
          id: Ident,
          scope: UserTaskScope
      ): OptionT[F, UserTask[NotifyDueItemsArgs]] =
        OptionT(getNotifyDueItems(scope).find(_.id == id).compile.last)

      def submitNotifyDueItems(
          scope: UserTaskScope,
          subject: Option[String],
          task: UserTask[NotifyDueItemsArgs]
      ): F[Unit] =
        for {
          _ <- store.updateTask[NotifyDueItemsArgs](scope, subject, task)
          _ <- joex.notifyAllNodes
        } yield ()
    })

}
