package docspell.analysis.date

import java.time.LocalDate

import scala.util.Try

import cats.implicits._
import fs2.{Pure, Stream}

import docspell.analysis.split._
import docspell.common._

object DateFind {

  def findDates(text: String, lang: Language): Stream[Pure, NerDateLabel] =
    TextSplitter
      .splitToken(text, " \t.,\n\r/".toSet)
      .sliding(3)
      .filter(_.length == 3)
      .flatMap(q =>
        Stream.emits(
          SimpleDate
            .fromParts(q.toList, lang)
            .map(sd =>
              NerDateLabel(
                sd.toLocalDate,
                NerLabel(
                  text.substring(q.head.begin, q(2).end),
                  NerTag.Date,
                  q.head.begin,
                  q(2).end
                )
              )
            )
        )
      )

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

    // ymd ✔, ydm, dmy ✔, dym, myd, mdy ✔
    def fromParts(parts: List[Word], lang: Language): List[SimpleDate] = {
      val p0 = pattern0(lang)
      val p1 = pattern1(lang)
      val p2 = pattern2(lang)
      val p = lang match {
        case Language.English =>
          p2.alt(p1).map(t => t._1 ++ t._2).or(p2).or(p0).or(p1)
        case Language.German  => p1.or(p0).or(p2)
        case Language.French  => p1.or(p0).or(p2)
        case Language.Italian => p1.or(p0).or(p2)
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

      def alt(other: Reader[A]): Reader[(A, A)] =
        Reader(words => Result.combine(read(words), other.read(words)))

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

      def readFirst[A](f: Word => Option[A]): Reader[A] =
        Reader({
          case Nil => Result.Failure
          case a :: as =>
            f(a).map(value => Result.Success(value, as)).getOrElse(Result.Failure)
        })
    }

    sealed trait Result[+A] {
      def toOption: Option[A]
      def map[B](f: A => B): Result[B]
      def flatMap[B](f: A => Result[B]): Result[B]
      def next[B](r: Reader[B]): Result[(A, B)]
    }

    object Result {
      final case class Success[A](value: A, rest: List[Word]) extends Result[A] {
        val toOption                                 = Some(value)
        def flatMap[B](f: A => Result[B]): Result[B] = f(value)
        def map[B](f: A => B): Result[B]             = Success(f(value), rest)
        def next[B](r: Reader[B]): Result[(A, B)] =
          r.read(rest).map(b => (value, b))
      }
      final case object Failure extends Result[Nothing] {
        val toOption                                       = None
        def flatMap[B](f: Nothing => Result[B]): Result[B] = this
        def map[B](f: Nothing => B): Result[B]             = this
        def next[B](r: Reader[B]): Result[(Nothing, B)]    = this
      }
      def combine[A](r0: Result[A], r1: Result[A]): Result[(A, A)] =
        (r0, r1) match {
          case (Success(a0, _), Success(a1, r1)) =>
            Success((a0, a1), r1)
          case _ =>
            Failure
        }
    }
  }
}
