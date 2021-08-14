/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.usertask

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.store.queries.QUserTask
import docspell.store.{AddResult, Store}

import io.circe._

/** User tasks are `RPeriodicTask`s that can be managed by the user.
  * The user can change arguments, enable/disable it or run it just
  * once.
  *
  * This class defines methods at a higher level, dealing with
  * `UserTask` and `AccountId` instead of directly using
  * `RPeriodicTask`. A user task is associated to a specific user (not
  * just the collective).
  *
  * implNote: The mapping is as follows: The collective is the task
  * group. The submitter property contains the username. Once a task
  * is saved to the database, it can only be refernced uniquely by its
  * id. A user may submit multiple same tasks (with different
  * properties).
  */
trait UserTaskStore[F[_]] {

  /** Return all tasks of the given user.
    */
  def getAll(account: AccountId): Stream[F, UserTask[String]]

  /** Return all tasks of the given name and user. The task's arguments
    * are returned as stored in the database.
    */
  def getByNameRaw(account: AccountId, name: Ident): Stream[F, UserTask[String]]

  /** Return all tasks of the given name and user. The task's arguments
    * are decoded using the given json decoder.
    */
  def getByName[A](account: AccountId, name: Ident)(implicit
      D: Decoder[A]
  ): Stream[F, UserTask[A]]

  /** Return a user-task with the given id. */
  def getByIdRaw(account: AccountId, id: Ident): OptionT[F, UserTask[String]]

  /** Updates or inserts the given task.
    *
    * The task is identified by its id. If no task with this id
    * exists, a new one is created. Otherwise the existing task is
    * updated.
    */
  def updateTask[A](account: AccountId, ut: UserTask[A])(implicit E: Encoder[A]): F[Int]

  /** Delete the task with the given id of the given user.
    */
  def deleteTask(account: AccountId, id: Ident): F[Int]

  /** Return the task of the given user and name. If multiple exists, an
    * error is returned. The task's arguments are returned as stored
    * in the database.
    */
  def getOneByNameRaw(account: AccountId, name: Ident): OptionT[F, UserTask[String]]

  /** Return the task of the given user and name. If multiple exists, an
    * error is returned. The task's arguments are decoded using the
    * given json decoder.
    */
  def getOneByName[A](account: AccountId, name: Ident)(implicit
      D: Decoder[A]
  ): OptionT[F, UserTask[A]]

  /** Updates or inserts the given task.
    *
    * Unlike `updateTask`, this ensures that there is at most one task
    * of some name in the db. Multiple same tasks (task with same
    * name) may not be allowed to run, depending on what they do.
    * This is not ensured by the database, though.
    *
    * If there are currently multiple tasks with same name as `ut` for
    * the user `account`, they will all be removed and the given task
    * inserted!
    */
  def updateOneTask[A](account: AccountId, ut: UserTask[A])(implicit
      E: Encoder[A]
  ): F[UserTask[String]]

  /** Delete all tasks of the given user that have name `name'.
    */
  def deleteAll(account: AccountId, name: Ident): F[Int]
}

object UserTaskStore {

  def apply[F[_]: Async](store: Store[F]): Resource[F, UserTaskStore[F]] =
    Resource.pure[F, UserTaskStore[F]](new UserTaskStore[F] {

      def getAll(account: AccountId): Stream[F, UserTask[String]] =
        store.transact(QUserTask.findAll(account))

      def getByNameRaw(account: AccountId, name: Ident): Stream[F, UserTask[String]] =
        store.transact(QUserTask.findByName(account, name))

      def getByIdRaw(account: AccountId, id: Ident): OptionT[F, UserTask[String]] =
        OptionT(store.transact(QUserTask.findById(account, id)))

      def getByName[A](account: AccountId, name: Ident)(implicit
          D: Decoder[A]
      ): Stream[F, UserTask[A]] =
        getByNameRaw(account, name).flatMap(_.decode match {
          case Right(ua) => Stream.emit(ua)
          case Left(err) => Stream.raiseError[F](new Exception(err))
        })

      def updateTask[A](account: AccountId, ut: UserTask[A])(implicit
          E: Encoder[A]
      ): F[Int] = {
        val exists = QUserTask.exists(ut.id)
        val insert = QUserTask.insert(account, ut.encode)
        store.add(insert, exists).flatMap {
          case AddResult.Success =>
            1.pure[F]
          case AddResult.EntityExists(_) =>
            store.transact(QUserTask.update(account, ut.encode))
          case AddResult.Failure(ex) =>
            Async[F].raiseError(ex)
        }
      }

      def deleteTask(account: AccountId, id: Ident): F[Int] =
        store.transact(QUserTask.delete(account, id))

      def getOneByNameRaw(
          account: AccountId,
          name: Ident
      ): OptionT[F, UserTask[String]] =
        OptionT(
          getByNameRaw(account, name)
            .take(2)
            .compile
            .toList
            .flatMap {
              case Nil       => (None: Option[UserTask[String]]).pure[F]
              case ut :: Nil => ut.some.pure[F]
              case _         => Async[F].raiseError(new Exception("More than one result found"))
            }
        )

      def getOneByName[A](account: AccountId, name: Ident)(implicit
          D: Decoder[A]
      ): OptionT[F, UserTask[A]] =
        getOneByNameRaw(account, name)
          .semiflatMap(_.decode match {
            case Right(ua) => ua.pure[F]
            case Left(err) => Async[F].raiseError(new Exception(err))
          })

      def updateOneTask[A](account: AccountId, ut: UserTask[A])(implicit
          E: Encoder[A]
      ): F[UserTask[String]] =
        getByNameRaw(account, ut.name).compile.toList.flatMap {
          case a :: rest =>
            val task = ut.copy(id = a.id).encode
            for {
              _ <- store.transact(QUserTask.update(account, task))
              _ <- store.transact(rest.traverse(t => QUserTask.delete(account, t.id)))
            } yield task
          case Nil =>
            val task = ut.encode
            store.transact(QUserTask.insert(account, task)).map(_ => task)
        }

      def deleteAll(account: AccountId, name: Ident): F[Int] =
        store.transact(QUserTask.deleteAll(account, name))
    })

}
