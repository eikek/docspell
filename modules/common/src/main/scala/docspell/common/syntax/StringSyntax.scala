package docspell.common.syntax

import cats.implicits._

import io.circe.Decoder
import io.circe.parser._

trait StringSyntax {

  implicit class EvenMoreStringOps(s: String) {

    def asNonBlank: Option[String] =
      Option(s).filter(_.trim.nonEmpty)

    def parseJsonAs[A](implicit d: Decoder[A]): Either[Throwable, A] =
      for {
        json  <- parse(s).leftMap(_.underlying)
        value <- json.as[A]
      } yield value
  }

}
