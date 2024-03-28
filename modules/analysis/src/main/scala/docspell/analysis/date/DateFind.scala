/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.analysis.date

import java.time.LocalDate

import scala.util.Try

import cats.data.{NonEmptyList => Nel}
import cats.implicits._
import cats.kernel.Semigroup
import fs2.{Pure, Stream}

import docspell.analysis.split._
import docspell.common._

object DateFind {

  def findDates(text: String, lang: Language): Stream[Pure, NerDateLabel] =
    splitWords(text, lang)
      .sliding(3)
      .filter(_.size == 3)
      .flatMap(q =>
        Stream.emits(
          SimpleDate
            .fromParts(q.toList, lang)
            .map(sd =>
              NerDateLabel(
                sd.toLocalDate,
                NerLabel(
                  text.substring(q.head.get.begin, q(2).end),
                  NerTag.Date,
                  q.head.get.begin,
                  q(2).end
                )
              )
            )
        )
      )

  private[this] val jpnChars =
    ("年月日" + MonthName.getAll(Language.Japanese).map(_.mkString).mkString).toSet

  private[date] def splitWords(text: String, lang: Language): Stream[Pure, Word] = {
    val sep = " -\t.,\n\r/"
    val (separators, stext) =
      if (lang == Language.Japanese) {
        (sep + "年月日") -> text.map(c => if (jpnChars.contains(c)) c else ' ')
      } else if (lang == Language.Lithuanian) {
        (sep + "md") -> text
      } else sep -> text

    val ukrFlexion = List(
      "р",
      "рік",
      "року",
      "ого",
      "го",
      "ий",
      "ій",
      "й",
      "ше",
      "ге",
      "тє",
      "те",
      "ме",
      "е",
      "є"
    )
    TextSplitter
      .splitToken(stext, separators.toSet)
      .filter(w => lang != Language.Latvian || w.value != "gada")
      .filter(w => lang != Language.Spanish || w.value != "de")
      .filter(w => lang != Language.Ukrainian || !ukrFlexion.contains(w.value))
  }

  case class SimpleDate(year: Int, month: Int, day: Int) {
    def toLocalDate: LocalDate =
      LocalDate.of(if (year < 100) 2000 + year else year, month, day)
  }

  object SimpleDate {
    def pattern0(lang: Language) = (readYear >> readMonth(lang) >> readDay).map {
      case ((y, m), d) =>
        List(SimpleDate(y, m, d))
    }
    def pattern1(lang: Language) = (readDay >> readMonth(lang) >> readYear).map {
      case ((d, m), y) =>
        List(SimpleDate(y, m, d))
    }
    def pattern2(lang: Language) = (readMonth(lang) >> readDay >> readYear).map {
      case ((m, d), y) =>
        List(SimpleDate(y, m, d))
    }
    def lavLong =
      (readYear >> readDay >> readMonth(Language.Latvian)).map { case ((y, d), m) =>
        List(SimpleDate(y, m, d))
      }

    // ymd ✔, ydm, dmy ✔, dym, myd, mdy ✔
    def fromParts(parts: List[Word], lang: Language): List[SimpleDate] = {
      val ymd = pattern0(lang)
      val dmy = pattern1(lang)
      val mdy = pattern2(lang)
      // most is from wikipedia…
      val p = lang match {
        case Language.English    => Reader.all(dmy, mdy, ymd)
        case Language.German     => dmy.or(ymd).or(mdy)
        case Language.French     => dmy.or(ymd).or(mdy)
        case Language.Italian    => dmy.or(ymd).or(mdy)
        case Language.Spanish    => dmy.or(ymd).or(mdy)
        case Language.Hungarian  => ymd
        case Language.Czech      => dmy.or(ymd).or(mdy)
        case Language.Danish     => dmy.or(ymd).or(mdy)
        case Language.Finnish    => dmy.or(ymd).or(mdy)
        case Language.Norwegian  => dmy.or(ymd).or(mdy)
        case Language.Portuguese => dmy.or(ymd).or(mdy)
        case Language.Romanian   => dmy.or(ymd).or(mdy)
        case Language.Russian    => dmy.or(ymd).or(mdy)
        case Language.Swedish    => ymd.or(dmy).or(mdy)
        case Language.Dutch      => dmy.or(ymd).or(mdy)
        case Language.Latvian    => dmy.or(lavLong).or(ymd)
        case Language.Japanese   => ymd
        case Language.JpnVert    => ymd
        case Language.Hebrew     => dmy
        case Language.Lithuanian => ymd
        case Language.Polish     => dmy
        case Language.Estonian   => dmy
        case Language.Khmer      => dmy
        case Language.Ukrainian  => dmy.or(ymd)
        case Language.Slovak     => dmy.or(ymd)
      }
      p.read(parts) match {
        case Result.Success(sds, _) =>
          sds.flatMap(sd => Either.catchNonFatal(sd.toLocalDate).toOption.map(_ => sd))
        case Result.Failure =>
          Nil
      }
    }

    def readYear: Reader[Int] =
      Reader.readFirst(w =>
        w.value.length match {
          case 2 => Try(w.value.toInt).filter(n => n >= 0).toOption
          case 4 => Try(w.value.toInt).filter(n => n > 1000).toOption
          case _ => None
        }
      )

    def readMonth(lang: Language): Reader[Int] =
      Reader.readFirst(w =>
        Some(MonthName.getAll(lang).indexWhere(_.contains(w.value)))
          .filter(_ >= 0)
          .map(_ + 1)
      )

    def readDay: Reader[Int] =
      Reader.readFirst(w => Try(w.value.toInt).filter(n => n > 0 && n <= 31).toOption)

    case class Reader[A](read: List[Word] => Result[A]) {
      def >>[B](next: Reader[B]): Reader[(A, B)] =
        Reader(read.andThen(_.next(next)))

      def map[B](f: A => B): Reader[B] =
        Reader(read.andThen(_.map(f)))

      def flatMap[B](f: A => Reader[B]): Reader[B] =
        Reader(read.andThen {
          case Result.Success(a, rest) => f(a).read(rest)
          case Result.Failure          => Result.Failure
        })

      def or(other: Reader[A]): Reader[A] =
        Reader(words =>
          read(words) match {
            case Result.Failure           => other.read(words)
            case s @ Result.Success(_, _) => s
          }
        )
    }

    object Reader {
      def fail[A]: Reader[A] =
        Reader(_ => Result.Failure)

      def all[A: Semigroup](reader: Reader[A], more: Reader[A]*): Reader[A] =
        Reader(words => Nel.of(reader, more: _*).map(_.read(words)).reduce)

      def readFirst[A](f: Word => Option[A]): Reader[A] =
        Reader {
          case Nil => Result.Failure
          case a :: as =>
            f(a).map(value => Result.Success(value, as)).getOrElse(Result.Failure)
        }
    }

    sealed trait Result[+A] {
      def toOption: Option[A]
      def map[B](f: A => B): Result[B]
      def flatMap[B](f: A => Result[B]): Result[B]
      def next[B](r: Reader[B]): Result[(A, B)]
    }

    object Result {
      final case class Success[A](value: A, rest: List[Word]) extends Result[A] {
        val toOption = Some(value)
        def flatMap[B](f: A => Result[B]): Result[B] = f(value)
        def map[B](f: A => B): Result[B] = Success(f(value), rest)
        def next[B](r: Reader[B]): Result[(A, B)] =
          r.read(rest).map(b => (value, b))
      }
      final case object Failure extends Result[Nothing] {
        val toOption = None
        def flatMap[B](f: Nothing => Result[B]): Result[B] = this
        def map[B](f: Nothing => B): Result[B] = this
        def next[B](r: Reader[B]): Result[(Nothing, B)] = this
      }

      implicit def resultSemigroup[A: Semigroup]: Semigroup[Result[A]] =
        Semigroup.instance { (r0, r1) =>
          (r0, r1) match {
            case (Success(a0, r0), Success(a1, r1)) =>
              Success(Semigroup[A].combine(a0, a1), if (r0.size < r1.size) r0 else r1)

            case (s @ Success(_, _), Failure) =>
              s

            case (Failure, s @ Success(_, _)) =>
              s

            case (Failure, Failure) =>
              Failure
          }
        }
    }
  }
}
