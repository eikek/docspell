package docspell.store.queries

import fs2._

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.records._
import docspell.store.usertask.UserTask

import doobie._

object QUserTask {
  private val cols = RPeriodicTask.Columns

  def findAll(account: AccountId): Stream[ConnectionIO, UserTask[String]] =
    selectSimple(
      RPeriodicTask.Columns.all,
      RPeriodicTask.table,
      and(cols.group.is(account.collective), cols.submitter.is(account.user))
    ).query[RPeriodicTask].stream.map(makeUserTask)

  def findByName(
      account: AccountId,
      name: Ident
  ): Stream[ConnectionIO, UserTask[String]] =
    selectSimple(
      RPeriodicTask.Columns.all,
      RPeriodicTask.table,
      and(
        cols.group.is(account.collective),
        cols.submitter.is(account.user),
        cols.task.is(name)
      )
    ).query[RPeriodicTask].stream.map(makeUserTask)

  def findById(
      account: AccountId,
      id: Ident
  ): ConnectionIO[Option[UserTask[String]]] =
    selectSimple(
      RPeriodicTask.Columns.all,
      RPeriodicTask.table,
      and(
        cols.group.is(account.collective),
        cols.submitter.is(account.user),
        cols.id.is(id)
      )
    ).query[RPeriodicTask].option.map(_.map(makeUserTask))

  def insert(account: AccountId, task: UserTask[String]): ConnectionIO[Int] =
    for {
      r <- task.toPeriodicTask[ConnectionIO](account)
      n <- RPeriodicTask.insert(r)
    } yield n

  def update(account: AccountId, task: UserTask[String]): ConnectionIO[Int] =
    for {
      r <- task.toPeriodicTask[ConnectionIO](account)
      n <- RPeriodicTask.update(r)
    } yield n

  def exists(id: Ident): ConnectionIO[Boolean] =
    RPeriodicTask.exists(id)

  def delete(account: AccountId, id: Ident): ConnectionIO[Int] =
    deleteFrom(
      RPeriodicTask.table,
      and(
        cols.group.is(account.collective),
        cols.submitter.is(account.user),
        cols.id.is(id)
      )
    ).update.run

  def deleteAll(account: AccountId, name: Ident): ConnectionIO[Int] =
    deleteFrom(
      RPeriodicTask.table,
      and(
        cols.group.is(account.collective),
        cols.submitter.is(account.user),
        cols.task.is(name)
      )
    ).update.run

  def makeUserTask(r: RPeriodicTask): UserTask[String] =
    UserTask(r.id, r.task, r.enabled, r.timer, r.args)

}
