package docspell.query

import java.time.LocalDate
import java.time.Period

import cats.implicits._

sealed trait Date

object Date {
  def apply(y: Int, m: Int, d: Int): Either[Throwable, DateLiteral] =
    Either.catchNonFatal(Local(LocalDate.of(y, m, d)))

  def apply(ms: Long): DateLiteral =
    Millis(ms)

  sealed trait DateLiteral extends Date

  final case class Local(date: LocalDate) extends DateLiteral

  final case class Millis(ms: Long) extends DateLiteral

  case object Today extends DateLiteral

  sealed trait CalcDirection
  object CalcDirection {
    case object Plus  extends CalcDirection
    case object Minus extends CalcDirection
  }

  case class Calc(date: DateLiteral, calc: CalcDirection, period: Period) extends Date
}
