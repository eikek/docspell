package docspell.store

import cats.implicits._
import cats.ApplicativeError

sealed trait UpdateResult

object UpdateResult {

  case object Success                     extends UpdateResult
  case object NotFound                    extends UpdateResult
  final case class Failure(ex: Throwable) extends UpdateResult

  def success: UpdateResult                = Success
  def notFound: UpdateResult               = NotFound
  def failure(ex: Throwable): UpdateResult = Failure(ex)

  def fromUpdateRows(n: Int): UpdateResult =
    if (n > 0) success
    else notFound

  def fromUpdate[F[_]](
      fn: F[Int]
  )(implicit ev: ApplicativeError[F, Throwable]): F[UpdateResult] =
    fn.attempt.map {
      case Right(n) => fromUpdateRows(n)
      case Left(ex) => failure(ex)
    }
}
