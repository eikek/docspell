/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.{NonEmptyList, OptionT}
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.notification.api.{ChannelRef, PeriodicDueItemsArgs, PeriodicQueryArgs}
import docspell.scheduler.usertask.{UserTask, UserTaskScope, UserTaskStore}
import docspell.store.Store
import docspell.store.records.RNotificationChannel

import io.circe.Encoder

trait OUserTask[F[_]] {

  /** Return the settings for all periodic-query tasks of the given user */
  def getPeriodicQuery(scope: UserTaskScope): Stream[F, UserTask[PeriodicQueryArgs]]

  /** Find a periodic-query task by the given id. */
  def findPeriodicQuery(
      id: Ident,
      scope: UserTaskScope
  ): OptionT[F, UserTask[PeriodicQueryArgs]]

  /** Updates the periodic-query task of the given user. */
  def submitPeriodicQuery(
      scope: UserTaskScope,
      subject: Option[String],
      task: UserTask[PeriodicQueryArgs]
  ): F[Unit]

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
  def getNotifyDueItems(scope: UserTaskScope): Stream[F, UserTask[PeriodicDueItemsArgs]]

  /** Find a notify-due-items task by the given id. */
  def findNotifyDueItems(
      id: Ident,
      scope: UserTaskScope
  ): OptionT[F, UserTask[PeriodicDueItemsArgs]]

  /** Updates the notify-due-items tasks and notifies the joex nodes. */
  def submitNotifyDueItems(
      scope: UserTaskScope,
      subject: Option[String],
      task: UserTask[PeriodicDueItemsArgs]
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
      taskStore: UserTaskStore[F],
      store: Store[F],
      joex: OJoex[F]
  ): Resource[F, OUserTask[F]] =
    Resource.pure[F, OUserTask[F]](new OUserTask[F] {

      def executeNow[A](scope: UserTaskScope, subject: Option[String], task: UserTask[A])(
          implicit E: Encoder[A]
      ): F[Unit] =
        taskStore.executeNow(scope, subject, task)

      def getScanMailbox(scope: UserTaskScope): Stream[F, UserTask[ScanMailboxArgs]] =
        taskStore
          .getByName[ScanMailboxArgs](scope, ScanMailboxArgs.taskName)

      def findScanMailbox(
          id: Ident,
          scope: UserTaskScope
      ): OptionT[F, UserTask[ScanMailboxArgs]] =
        OptionT(getScanMailbox(scope).find(_.id == id).compile.last)

      def deleteTask(scope: UserTaskScope, id: Ident): F[Unit] =
        (for {
          _ <- taskStore.getByIdRaw(scope, id)
          _ <- OptionT.liftF(taskStore.deleteTask(scope, id))
        } yield ()).getOrElse(())

      def submitScanMailbox(
          scope: UserTaskScope,
          subject: Option[String],
          task: UserTask[ScanMailboxArgs]
      ): F[Unit] =
        for {
          _ <- taskStore.updateTask[ScanMailboxArgs](scope, subject, task)
          _ <- joex.notifyPeriodicTasks
        } yield ()

      def getNotifyDueItems(
          scope: UserTaskScope
      ): Stream[F, UserTask[PeriodicDueItemsArgs]] =
        taskStore
          .getByName[PeriodicDueItemsArgs](scope, PeriodicDueItemsArgs.taskName)
          .evalMap(ut =>
            resolveChannels(ut.args.channels)
              .map(chs => ut.mapArgs(_.copy(channels = chs)))
          )

      def findNotifyDueItems(
          id: Ident,
          scope: UserTaskScope
      ): OptionT[F, UserTask[PeriodicDueItemsArgs]] =
        OptionT(getNotifyDueItems(scope).find(_.id == id).compile.last)
          .semiflatMap(ut =>
            resolveChannels(ut.args.channels).map(ch => ut.mapArgs(_.copy(channels = ch)))
          )

      def submitNotifyDueItems(
          scope: UserTaskScope,
          subject: Option[String],
          task: UserTask[PeriodicDueItemsArgs]
      ): F[Unit] =
        for {
          _ <- taskStore.updateTask[PeriodicDueItemsArgs](scope, subject, task)
          _ <- joex.notifyPeriodicTasks
        } yield ()

      def getPeriodicQuery(scope: UserTaskScope): Stream[F, UserTask[PeriodicQueryArgs]] =
        taskStore
          .getByName[PeriodicQueryArgs](scope, PeriodicQueryArgs.taskName)
          .evalMap(ut =>
            resolveChannels(ut.args.channels)
              .map(chs => ut.mapArgs(_.copy(channels = chs)))
          )

      def findPeriodicQuery(
          id: Ident,
          scope: UserTaskScope
      ): OptionT[F, UserTask[PeriodicQueryArgs]] =
        OptionT(getPeriodicQuery(scope).find(_.id == id).compile.last)
          .semiflatMap(ut =>
            resolveChannels(ut.args.channels).map(ch => ut.mapArgs(_.copy(channels = ch)))
          )

      def submitPeriodicQuery(
          scope: UserTaskScope,
          subject: Option[String],
          task: UserTask[PeriodicQueryArgs]
      ): F[Unit] =
        for {
          _ <- taskStore.updateTask[PeriodicQueryArgs](scope, subject, task)
          _ <- joex.notifyPeriodicTasks
        } yield ()

      // When retrieving arguments containing channel references, we must update
      // details because they could have changed in the db. There are no separate
      // database models for each user task, so rather a hacky compromise
      private def resolveChannels(
          refs: NonEmptyList[ChannelRef]
      ): F[NonEmptyList[ChannelRef]] =
        store.transact(RNotificationChannel.resolveRefs(refs)).map { resolved =>
          NonEmptyList.fromList(resolved).getOrElse(refs)
        }
    })
}
