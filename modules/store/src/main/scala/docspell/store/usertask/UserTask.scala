package docspell.store.usertask

import com.github.eikek.calev.CalEvent
import io.circe.Decoder
import io.circe.Encoder
import docspell.common._
import docspell.common.syntax.all._

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
      ut.args.parseJsonAs[A]
        .left.map(_.getMessage)
        .map(a => ut.copy(args = a))

  }

}
