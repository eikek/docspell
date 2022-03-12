package docspell.scheduler.usertask

import cats.implicits._
import cats.effect.Sync
import com.github.eikek.calev.CalEvent
import docspell.common._
import docspell.store.qb.DML
import docspell.store.qb.DSL._
import docspell.store.records.RPeriodicTask
import doobie.ConnectionIO
import fs2.Stream
import io.circe.Encoder

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

  def insert(
      scope: UserTaskScope,
      subject: Option[String],
      task: UserTask[String]
  ): ConnectionIO[Int] =
    for {
      r <- task.toPeriodicTask[ConnectionIO](scope, subject)
      n <- RPeriodicTask.insert(r)
    } yield n

  def update(
      scope: UserTaskScope,
      subject: Option[String],
      task: UserTask[String]
  ): ConnectionIO[Int] =
    for {
      r <- task.toPeriodicTask[ConnectionIO](scope, subject)
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

  def create[F[_]: Sync](
      enabled: Boolean,
      scope: UserTaskScope,
      task: Ident,
      args: String,
      subject: String,
      priority: Priority,
      timer: CalEvent,
      summary: Option[String]
  ): F[RPeriodicTask] =
    Ident
      .randomId[F]
      .flatMap(id =>
        Timestamp
          .current[F]
          .map { now =>
            RPeriodicTask(
              id,
              enabled,
              task,
              scope.collective,
              args,
              subject,
              scope.fold(_.user, identity),
              priority,
              None,
              None,
              timer,
              timer
                .nextElapse(now.atZone(Timestamp.UTC))
                .map(_.toInstant)
                .map(Timestamp.apply)
                .getOrElse(Timestamp.Epoch),
              now,
              summary
            )
          }
      )

  def createJson[F[_]: Sync, A](
      enabled: Boolean,
      scope: UserTaskScope,
      task: Ident,
      args: A,
      subject: String,
      priority: Priority,
      timer: CalEvent,
      summary: Option[String]
  )(implicit E: Encoder[A]): F[RPeriodicTask] =
    create[F](
      enabled,
      scope,
      task,
      E(args).noSpaces,
      subject,
      priority,
      timer,
      summary
    )

}
