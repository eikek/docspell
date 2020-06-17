package docspell.restserver.http4s

import cats.implicits._
import cats.Applicative
import org.http4s.{EntityEncoder, Header, Response}
import org.http4s.dsl.Http4sDsl

trait ResponseGenerator[F[_]] {
  self: Http4sDsl[F] =>

  implicit final class EitherResponses[A, B](e: Either[A, B]) {
    def toResponse(headers: Header*)(implicit
        F: Applicative[F],
        w0: EntityEncoder[F, A],
        w1: EntityEncoder[F, B]
    ): F[Response[F]] =
      e.fold(
        a => UnprocessableEntity(a),
        b => Ok(b)
      ).map(_.withHeaders(headers: _*))
  }

  implicit final class OptionResponse[A](o: Option[A]) {
    def toResponse(
        headers: Header*
    )(implicit F: Applicative[F], w0: EntityEncoder[F, A]): F[Response[F]] =
      o.map(a => Ok(a)).getOrElse(NotFound()).map(_.withHeaders(headers: _*))
  }

}

object ResponseGenerator {}
