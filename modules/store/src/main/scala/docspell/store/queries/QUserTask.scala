package docspell.store.queries

import fs2._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records._
import docspell.store.usertask.UserTask

import doobie._

object QUserTask {
  private val RT = RPeriodicTask.T

  def findAll(account: AccountId): Stream[ConnectionIO, UserTask[String]] =
    run(
      select(RT.all),
      from(RT),
      RT.group === account.collective && RT.submitter === account.user
    ).query[RPeriodicTask].stream.map(makeUserTask)

  def findByName(
      account: AccountId,
      name: Ident
  ): Stream[ConnectionIO, UserTask[String]] =
    run(
      select(RT.all),
      from(RT),
      where(
        RT.group === account.collective,
        RT.submitter === account.user,
        RT.task === name
      )
    ).query[RPeriodicTask].stream.map(makeUserTask)

  def findById(
      account: AccountId,
      id: Ident
  ): ConnectionIO[Option[UserTask[String]]] =
    run(
      select(RT.all),
      from(RT),
      where(
        RT.group === account.collective,
        RT.submitter === account.user,
        RT.id === id
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
    DML
      .delete(
        RT,
        where(
          RT.group === account.collective,
          RT.submitter === account.user,
          RT.id === id
        )
      )

  def deleteAll(account: AccountId, name: Ident): ConnectionIO[Int] =
    DML.delete(
      RT,
      where(
        RT.group === account.collective,
        RT.submitter === account.user,
        RT.task === name
      )
    )

  def makeUserTask(r: RPeriodicTask): UserTask[String] =
    UserTask(r.id, r.task, r.enabled, r.timer, r.summary, r.args)

}
