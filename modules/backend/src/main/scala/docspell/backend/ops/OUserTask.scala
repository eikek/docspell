package docspell.backend.ops

import cats.implicits._
import cats.effect._
import docspell.store.usertask._
import docspell.common._
import com.github.eikek.calev.CalEvent

trait OUserTask[F[_]] {

  def getNotifyDueItems(account: AccountId): F[UserTask[NotifyDueItemsArgs]]

  def submitNotifyDueItems(
      account: AccountId,
      task: UserTask[NotifyDueItemsArgs]
  ): F[Unit]

}

object OUserTask {

  def apply[F[_]: Effect](store: UserTaskStore[F], joex: OJoex[F]): Resource[F, OUserTask[F]] =
    Resource.pure[F, OUserTask[F]](new OUserTask[F] {

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
            Ident.unsafe("none"),
            Nil,
            5,
            Nil,
            Nil
          )
        )
    })

}
