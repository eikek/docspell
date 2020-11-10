package docspell.common

import cats.implicits._
import cats.data.NonEmptyList
import io.circe.{Decoder, Encoder}

/** A very simple glob supporting only `*` and `?`. */
final case class Glob(pattern: Glob.Pattern) {
  def matches(in: String): Boolean =
    pattern.parts
      .zipWith(Glob.split(in, Glob.separator))(_.matches(_))
      .forall(identity)

  def asString: String =
    pattern.asString
}

object Glob {
  private val separator = '/'

  def apply(str: String): Glob =
    Glob(Pattern(split(str, separator).map(makeSegment)))

  case class Pattern(parts: NonEmptyList[Segment])  {
    def asString =
      parts.map(_.asString).toList.mkString(separator.toString)
  }

  object Pattern {
    def apply(s0: Segment, sm: Segment*): Pattern =
      Pattern(NonEmptyList.of(s0, sm: _*))
  }

  case class Segment(tokens: NonEmptyList[Token]) {
    def matches(in: String): Boolean =
      consume(in).exists(_.isEmpty)

    def consume(in: String): Option[String] =
      tokens.foldLeft(in.some) { (rem, token) =>
        rem.flatMap(token.consume)
      }

    def asString: String =
      tokens.toList.map(_.asString).mkString
  }
  object Segment {
    def apply(t0: Token, ts: Token*): Segment =
      Segment(NonEmptyList.of(t0, ts: _*))
  }

  sealed trait Token {
    def consume(str: String): Option[String]

    def asString: String
  }
  object Token {
    case class Literal(asString: String) extends Token {
      def consume(str: String): Option[String] =
        if (str.startsWith(asString)) str.drop(asString.length).some
        else None
    }
    case class Until(value: String) extends Token {
      def consume(str: String): Option[String] =
        if (value.isEmpty) Some("")
        else
          str.indexOf(value) match {
            case -1 => None
            case n  => str.substring(n + value.length).some
          }
      val asString =
        s"*$value"
    }
    case object Single extends Token {
      def consume(str: String): Option[String] =
        if (str.isEmpty()) None
        else Some(str.drop(1))

      val asString = "?"
    }
  }

  private def split(str: String, sep: Char): NonEmptyList[String] =
    NonEmptyList
      .fromList(str.split(sep).toList)
      .getOrElse(NonEmptyList.of(str))

  private def makeSegment(str: String): Segment = {
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
