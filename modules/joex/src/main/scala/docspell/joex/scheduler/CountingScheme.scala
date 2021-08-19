/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.scheduler

import cats.implicits._

import docspell.common.Priority

/** A counting scheme to indicate a ratio between scheduling high and low priority jobs.
  *
  * For example high=4, low=1 means: ”schedule 4 high priority jobs and then 1 low
  * priority job“.
  */
case class CountingScheme(high: Int, low: Int, counter: Int = 0) {

  def nextPriority: (CountingScheme, Priority) =
    if (counter <= 0) (increment, Priority.High)
    else {
      val rest = counter % (high + low)
      if (rest < high) (increment, Priority.High)
      else (increment, Priority.Low)
    }

  def increment: CountingScheme =
    copy(counter = counter + 1)
}

object CountingScheme {

  def writeString(cs: CountingScheme): String =
    s"${cs.high},${cs.low}"

  def readString(str: String): Either[String, CountingScheme] =
    str.split(',') match {
      case Array(h, l) =>
        Either.catchNonFatal(CountingScheme(h.toInt, l.toInt)).left.map(_.getMessage)
      case _ =>
        Left(s"Invalid counting scheme: $str")
    }
}
