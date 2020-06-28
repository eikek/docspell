package docspell.restserver.http4s

import fs2.text.utf8Encode
import fs2.{Pure, Stream}

import org.http4s._
import org.http4s.headers._

object Responses {

  private[this] val pureForbidden: Response[Pure] =
    Response(
      Status.Forbidden,
      body = Stream("Forbidden").through(utf8Encode),
      headers = Headers(`Content-Type`(MediaType.text.plain, Charset.`UTF-8`) :: Nil)
    )

  private[this] val pureUnauthorized: Response[Pure] =
    Response(
      Status.Unauthorized,
      body = Stream("Unauthorized").through(utf8Encode),
      headers = Headers(`Content-Type`(MediaType.text.plain, Charset.`UTF-8`) :: Nil)
    )

  def forbidden[F[_]]: Response[F] =
    pureForbidden.copy(body = pureForbidden.body.covary[F])

  def unauthorized[F[_]]: Response[F] =
    pureUnauthorized.copy(body = pureUnauthorized.body.covary[F])
}
