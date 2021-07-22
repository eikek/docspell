/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.query.internal

import java.time.Period

import cats.data.{NonEmptyList => Nel}
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
    P.charIn('-', '/').void

  private val dateString: P[((Int, Option[Int]), Option[Int])] =
    digits4 ~ (dateSep *> month).? ~ (dateSep *> day).?

  private[internal] val dateFromString: P[Date.DateLiteral] =
    dateString.mapFilter { case ((year, month), day) =>
      Date(year, month.getOrElse(1), day.getOrElse(1)).toOption
    }

  private[internal] val dateFromMillis: P[Date.DateLiteral] =
    P.string("ms") *> longParser.map(Date.apply)

  private val dateFromToday: P[Date.DateLiteral] =
    P.string("today").as(Date.Today)

  val yearOnly: P[Int] =
    digits4

  val dateLiteral: P[Date.DateLiteral] =
    P.oneOf(List(dateFromString, dateFromToday, dateFromMillis))

  // val dateLiteralOrMore: P[NonEmptyList[Date.DateLiteral]] =
  //   dateLiteral.repSep(BasicParser.stringListSep)

  val dateCalcDirection: P[Date.CalcDirection] =
    P.oneOf(
      List(
        P.char('+').as(Date.CalcDirection.Plus),
        P.char('-').as(Date.CalcDirection.Minus)
      )
    )

  def periodPart(unitSuffix: Char, f: Int => Period): P[Period] =
    ((Numbers.nonZeroDigit ~ Numbers.digits0).void.string.soft <* P.ignoreCaseChar(
      unitSuffix
    ))
      .map(n => f(n.toInt))

  private[this] val periodMonths: P[Period] =
    periodPart('m', n => Period.ofMonths(n))

  private[this] val periodDays: P[Period] =
    periodPart('d', n => Period.ofDays(n))

  val period: P[Period] =
    periodDays.eitherOr(periodMonths).map(_.fold(identity, identity))

  val periods: P[Period] =
    period.rep.map(_.reduceLeft((p0, p1) => p0.plus(p1)))

  val dateRange: P[(Date, Date)] =
    ((dateLiteral <* P.char(';')) ~ dateCalcDirection.eitherOr(P.char('/')) ~ period)
      .map { case ((date, calc), period) =>
        calc match {
          case Right(Date.CalcDirection.Plus) =>
            (date, Date.Calc(date, Date.CalcDirection.Plus, period))
          case Right(Date.CalcDirection.Minus) =>
            (Date.Calc(date, Date.CalcDirection.Minus, period), date)
          case Left(_) =>
            (
              Date.Calc(date, Date.CalcDirection.Minus, period),
              Date.Calc(date, Date.CalcDirection.Plus, period)
            )
        }
      }

  val date: P[Date] =
    (dateLiteral ~ (P.char(';') *> dateCalcDirection ~ period).?).map {
      case (date, Some((c, p))) =>
        Date.Calc(date, c, p)

      case (date, None) =>
        date
    }

  val dateOrMore: P[Nel[Date]] =
    date.repSep(BasicParser.stringListSep)
}
