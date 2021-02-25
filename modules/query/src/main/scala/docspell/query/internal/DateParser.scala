package docspell.query.internal

import cats.implicits._
import cats.parse.{Numbers, Parser => P}

import docspell.query.Date

object DateParser {
  private[this] val longParser: P[Long] =
    Numbers.bigInt.map(_.longValue)

  private[this] val digits4: P[Int] =
    Numbers.digit
      .repExactlyAs[String](4)
      .map(_.toInt)
  private[this] val digits2: P[Int] =
    Numbers.digit
      .repExactlyAs[String](2)
      .map(_.toInt)

  private[this] val month: P[Int] =
    digits2.filter(n => n >= 1 && n <= 12)

  private[this] val day: P[Int] =
    digits2.filter(n => n >= 1 && n <= 31)

  private val dateSep: P[Unit] =
    P.anyChar.void

  val localDateFromString: P[Date] =
    ((digits4 <* dateSep) ~ (month <* dateSep) ~ day).mapFilter {
      case ((year, month), day) =>
        Either.catchNonFatal(Date(year, month, day)).toOption
    }

  val dateFromMillis: P[Date] =
    longParser.map(Date.apply)

  val localDate: P[Date] =
    localDateFromString.backtrack.orElse(dateFromMillis)

}
