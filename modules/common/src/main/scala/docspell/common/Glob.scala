/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList
import cats.implicits._

import io.circe.{Decoder, Encoder}

trait Glob {

  /** Matches the input string against this glob. */
  def matches(caseSensitive: Boolean)(in: String): Boolean

  /** If this glob consists of multiple segments, it is the same as `matches`. If it is
    * only a single segment, it is matched against the last segment of the input string
    * that is assumed to be a pathname separated by slash.
    *
    * Example: test.* <> "/a/b/test.txt" => true /test.* <> "/a/b/test.txt" => false
    */
  def matchFilenameOrPath(in: String): Boolean

  def asString: String
}

object Glob {
  def apply(in: String): Glob = {
    def single(str: String) =
      PatternGlob(Pattern(split(str, separator).map(makeSegment)))

    if (in == "*") all
    else
      split(in, anyChar) match {
        case NonEmptyList(_, Nil) =>
          single(in)
        case nel =>
          AnyGlob(nel.map(_.trim).map(single))
      }
  }

  private val separator = '/'
  private val anyChar   = '|'

  val all = new Glob {
    def matches(caseSensitive: Boolean)(in: String) = true
    def matchFilenameOrPath(in: String)             = true
    val asString                                    = "*"
  }

  def pattern(pattern: Pattern): Glob =
    PatternGlob(pattern)

  /** A simple glob supporting `*` and `?`. */
  final private case class PatternGlob(pattern: Pattern) extends Glob {
    def matches(caseSensitive: Boolean)(in: String): Boolean =
      pattern.parts
        .zipWith(Glob.split(in, Glob.separator))(_.matches(caseSensitive)(_))
        .forall(identity)

    def matchFilenameOrPath(in: String): Boolean =
      if (pattern.parts.tail.isEmpty) matches(true)(split(in, separator).last)
      else matches(true)(in)

    def asString: String =
      pattern.asString
  }

  final private case class AnyGlob(globs: NonEmptyList[Glob]) extends Glob {
    def matches(caseSensitive: Boolean)(in: String) =
      globs.exists(_.matches(caseSensitive)(in))
    def matchFilenameOrPath(in: String) =
      globs.exists(_.matchFilenameOrPath(in))
    def asString =
      globs.toList.map(_.asString).mkString(anyChar.toString)
  }

  case class Pattern(parts: NonEmptyList[Segment]) {
    def asString =
      parts.map(_.asString).toList.mkString(separator.toString)
  }

  object Pattern {
    def apply(s0: Segment, sm: Segment*): Pattern =
      Pattern(NonEmptyList.of(s0, sm: _*))
  }

  case class Segment(tokens: NonEmptyList[Token]) {
    def matches(caseSensitive: Boolean)(in: String): Boolean =
      consume(in, caseSensitive).exists(_.isEmpty)

    def consume(in: String, caseSensitive: Boolean): Option[String] =
      tokens.foldLeft(in.some) { (rem, token) =>
        rem.flatMap(token.consume(caseSensitive))
      }

    def asString: String =
      tokens.toList.map(_.asString).mkString
  }
  object Segment {
    def apply(t0: Token, ts: Token*): Segment =
      Segment(NonEmptyList.of(t0, ts: _*))
  }

  sealed trait Token {
    def consume(caseSensitive: Boolean)(str: String): Option[String]

    def asString: String
  }
  object Token {
    case class Literal(asString: String) extends Token {
      def consume(caseSensitive: Boolean)(str: String): Option[String] =
        if (str.startsWith(asString, caseSensitive)) str.drop(asString.length).some
        else None
    }
    case class Until(value: String) extends Token {
      def consume(caseSensitive: Boolean)(str: String): Option[String] =
        if (value.isEmpty) Some("")
        else
          str
            .findFirst(value, caseSensitive)
            .map(n => str.substring(n + value.length))
      val asString =
        s"*$value"
    }
    case object Single extends Token {
      def consume(caseSensitive: Boolean)(str: String): Option[String] =
        if (str.isEmpty) None
        else Some(str.drop(1))

      val asString = "?"
    }

    implicit final class StringHelper(val str: String) extends AnyVal {
      def findFirst(sub: String, caseSensitive: Boolean): Option[Int] = {
        val vstr = if (caseSensitive) str else str.toLowerCase
        val vsub = if (caseSensitive) sub else sub.toLowerCase
        Option(vstr.indexOf(vsub)).filter(_ >= 0)
      }

      def startsWith(prefix: String, caseSensitive: Boolean): Boolean = {
        val vstr    = if (caseSensitive) str else str.toLowerCase
        val vprefix = if (caseSensitive) prefix else prefix.toLowerCase
        vstr.startsWith(vprefix)
      }
    }
  }

  private def split(str: String, sep: Char): NonEmptyList[String] =
    NonEmptyList
      .fromList(str.split(sep).toList)
      .getOrElse(NonEmptyList.of(str))

  private def makeSegment(str: String): Segment = {
    @annotation.tailrec
    def loop(rem: String, res: List[Token]): List[Token] =
      if (rem.isEmpty) res
      else
        rem.charAt(0) match {
          case '*' =>
            val stop = rem.drop(1).takeWhile(c => c != '*' && c != '?')
            loop(rem.drop(1 + stop.length), Token.Until(stop) :: res)
          case '?' =>
            loop(rem.drop(1), Token.Single :: res)
          case _ =>
            val lit = rem.takeWhile(c => c != '*' && c != '?')
            loop(rem.drop(lit.length), Token.Literal(lit) :: res)
        }

    val fixed = str.replaceAll("\\*+", "*")
    NonEmptyList
      .fromList(loop(fixed, Nil).reverse)
      .map(Segment.apply)
      .getOrElse(Segment(Token.Literal(str)))
  }

  implicit val jsonEncoder: Encoder[Glob] =
    Encoder.encodeString.contramap(_.asString)

  implicit val jsonDecoder: Decoder[Glob] =
    Decoder.decodeString.map(Glob.apply)
}
