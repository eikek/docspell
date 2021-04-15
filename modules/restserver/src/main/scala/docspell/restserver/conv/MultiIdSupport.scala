package docspell.restserver.conv

import cats.data.NonEmptyList
import cats.implicits._
import cats.{ApplicativeError, MonadError}
import docspell.common.Ident
import io.circe.DecodingFailure

trait MultiIdSupport {

  protected def readId[F[_]](
      id: String
  )(implicit F: ApplicativeError[F, Throwable]): F[Ident] =
    Ident
      .fromString(id)
      .fold(
        err => F.raiseError(DecodingFailure(err, Nil)),
        F.pure
      )

  protected def readIds[F[_]](ids: List[String])(implicit
      F: MonadError[F, Throwable]
  ): F[NonEmptyList[Ident]] =
    ids.traverse(readId[F]).map(NonEmptyList.fromList).flatMap {
      case Some(nel) => nel.pure[F]
      case None =>
        F.raiseError(
          DecodingFailure("Empty list found, at least one element required", Nil)
        )
    }
}
