package docspell.joex.scheduler

import cats.implicits._
import cats.effect.Sync
import docspell.common.Ident
import docspell.common.syntax.all._
import io.circe.Decoder

/**
  * Binds a Task to a name. This is required to lookup the code based
  * on the taskName in the RJob data and to execute it given the
  * arguments that have to be read from a string.
  *
  * Since the scheduler only has a string for the task argument, this
  * only works for Task impls that accept a string. There is a
  * convenience constructor that uses circe to decode json into some
  * type A.
  */
case class JobTask[F[_]](name: Ident, task: Task[F, String, Unit], onCancel: Task[F, String, Unit])

object JobTask {

  def json[F[_]: Sync, A](name: Ident, task: Task[F, A, Unit], onCancel: Task[F, A, Unit])(
      implicit D: Decoder[A]
  ): JobTask[F] = {
    val convert: String => F[A] =
      str =>
        str.parseJsonAs[A] match {
          case Right(a) => a.pure[F]
          case Left(ex) =>
            Sync[F].raiseError(new Exception(s"Cannot parse task arguments: $str", ex))
        }

    JobTask(name, task.contramap(convert), onCancel.contramap(convert))
  }
}
