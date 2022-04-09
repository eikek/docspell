/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.scheduler.impl.QUserTask.UserTaskCodec
import docspell.scheduler.usertask.UserTaskStore
import docspell.scheduler.usertask._
import docspell.store.{AddResult, Store}

import io.circe._

final class UserTaskStoreImpl[F[_]: Sync](
    store: Store[F],
    periodicTaskStore: PeriodicTaskStore[F]
) extends UserTaskStore[F] {
  def getAll(scope: UserTaskScope): Stream[F, UserTask[String]] =
    store.transact(QUserTask.findAll(scope.toAccountId))

  def getByNameRaw(scope: UserTaskScope, name: Ident): Stream[F, UserTask[String]] =
    store.transact(QUserTask.findByName(scope.toAccountId, name))

  def getByIdRaw(scope: UserTaskScope, id: Ident): OptionT[F, UserTask[String]] =
    OptionT(store.transact(QUserTask.findById(scope.toAccountId, id)))

  def getByName[A](scope: UserTaskScope, name: Ident)(implicit
      D: Decoder[A]
  ): Stream[F, UserTask[A]] =
    getByNameRaw(scope, name).flatMap(_.decode match {
      case Right(ua) => Stream.emit(ua)
      case Left(err) => Stream.raiseError[F](new Exception(err))
    })

  def updateTask[A](scope: UserTaskScope, subject: Option[String], ut: UserTask[A])(
      implicit E: Encoder[A]
  ): F[Int] = {
    val exists = QUserTask.exists(ut.id)
    val insert = QUserTask.insert(scope, subject, ut.encode, silent = true)
    store.add(insert, exists).flatMap {
      case AddResult.Success =>
        1.pure[F]
      case AddResult.EntityExists(_) =>
        store.transact(QUserTask.update(scope, subject, ut.encode))
      case AddResult.Failure(ex) =>
        Sync[F].raiseError(ex)
    }
  }

  def deleteTask(scope: UserTaskScope, id: Ident): F[Int] =
    store.transact(QUserTask.delete(scope.toAccountId, id))

  def getOneByNameRaw(
      scope: UserTaskScope,
      name: Ident
  ): OptionT[F, UserTask[String]] =
    OptionT(
      getByNameRaw(scope, name)
        .take(2)
        .compile
        .toList
        .flatMap {
          case Nil       => (None: Option[UserTask[String]]).pure[F]
          case ut :: Nil => ut.some.pure[F]
          case _ => Sync[F].raiseError(new Exception("More than one result found"))
        }
    )

  def getOneByName[A](scope: UserTaskScope, name: Ident)(implicit
      D: Decoder[A]
  ): OptionT[F, UserTask[A]] =
    getOneByNameRaw(scope, name)
      .semiflatMap(_.decode match {
        case Right(ua) => ua.pure[F]
        case Left(err) => Sync[F].raiseError(new Exception(err))
      })

  def updateOneTask[A](
      scope: UserTaskScope,
      subject: Option[String],
      ut: UserTask[A]
  )(implicit
      E: Encoder[A]
  ): F[UserTask[String]] =
    getByNameRaw(scope, ut.name).compile.toList.flatMap {
      case a :: rest =>
        val task = ut.copy(id = a.id).encode
        for {
          _ <- store.transact(QUserTask.update(scope, subject, task))
          _ <- store.transact(
            rest.traverse(t => QUserTask.delete(scope.toAccountId, t.id))
          )
        } yield task
      case Nil =>
        val task = ut.encode
        store
          .transact(QUserTask.insert(scope, subject, task, silent = false))
          .map(_ => task)
    }

  def deleteAll(scope: UserTaskScope, name: Ident): F[Int] =
    store.transact(QUserTask.deleteAll(scope.toAccountId, name))

  def executeNow[A](scope: UserTaskScope, subject: Option[String], task: UserTask[A])(
      implicit E: Encoder[A]
  ): F[Unit] =
    for {
      ptask <- task.encode.toPeriodicTask(scope, subject)
      _ <- periodicTaskStore.submit(ptask)
    } yield ()
}

object UserTaskStoreImpl {
  def apply[F[_]: Sync](
      store: Store[F],
      periodicTaskStore: PeriodicTaskStore[F]
  ): UserTaskStore[F] =
    new UserTaskStoreImpl[F](store, periodicTaskStore)
}
