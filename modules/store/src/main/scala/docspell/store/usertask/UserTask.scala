package docspell.store.usertask

import cats.effect._
import cats.implicits._
import com.github.eikek.calev.CalEvent
import io.circe.Decoder
import io.circe.Encoder

import docspell.common._
import docspell.common.syntax.all._
import docspell.store.records.RPeriodicTask

case class UserTask[A](
    id: Ident,
    name: Ident,
    enabled: Boolean,
    timer: CalEvent,
    args: A
) {

  def encode(implicit E: Encoder[A]): UserTask[String] =
    copy(args = E(args).noSpaces)

}

object UserTask {

  implicit final class UserTaskCodec(ut: UserTask[String]) {

    def decode[A](implicit D: Decoder[A]): Either[String, UserTask[A]] =
      ut.args
        .parseJsonAs[A]
        .left
        .map(_.getMessage)
        .map(a => ut.copy(args = a))

    def toPeriodicTask[F[_]: Sync](
        account: AccountId
    ): F[RPeriodicTask] =
      RPeriodicTask
        .create[F](
          ut.enabled,
          ut.name,
          account.collective,
          ut.args,
          s"${account.user.id}: ${ut.name.id}",
          account.user,
          Priority.Low,
          ut.timer
        )
        .map(r => r.copy(id = ut.id))
  }
}
