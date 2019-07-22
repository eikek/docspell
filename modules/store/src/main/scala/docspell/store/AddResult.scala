package docspell.store

import AddResult._

sealed trait AddResult {
  def toEither: Either[Throwable, Unit]
  def isSuccess: Boolean

  def fold[A](fa: Success.type => A, fb: EntityExists => A, fc: Failure => A): A

  def isError: Boolean =
    !isSuccess
}

object AddResult {

  def fromUpdate(e: Either[Throwable, Int]): AddResult =
    e.fold(Failure, n => if (n > 0) Success else Failure(new Exception("No rows updated")))

  case object Success extends AddResult {
    def toEither = Right(())
    val isSuccess = true
    def fold[A](fa: Success.type => A, fb: EntityExists => A, fc: Failure => A): A =
      fa(this)
  }

  case class EntityExists(msg: String) extends AddResult {
    def toEither = Left(new Exception(msg))
    val isSuccess = false
    def fold[A](fa: Success.type => A, fb: EntityExists => A, fc: Failure => A): A =
      fb(this)

    def withMsg(msg: String): EntityExists =
      EntityExists(msg)
  }

  case class Failure(ex: Throwable) extends AddResult {
    def toEither = Left(ex)
    val isSuccess = false
    def fold[A](fa: Success.type => A, fb: EntityExists => A, fc: Failure => A): A =
      fc(this)
  }
}
