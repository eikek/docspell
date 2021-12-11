/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.http4s

import java.nio.charset.{Charset, StandardCharsets}

import cats.implicits._
import cats.parse.{Parser, Parser0, Rfc5234}

import org.http4s.headers.`Content-Disposition`
import org.http4s.internal.CharPredicate
import org.http4s.multipart.Part
import org.http4s.{Header, ParseFailure, ParseResult}
import org.typelevel.ci.CIString
import org.typelevel.ci._

/** A replacement for `Content-Disposition` class with a slightly modified parser to allow
  * utf8 filenames.
  *
  * The usage of this class is already in the `Part` class to retrieve the filename. This
  * class can be used as follows:
  *
  * {{{ContentDisposition.getFileName(part)}}}
  *
  * where `part` is of type `multipart.Part[F]`.
  */
case class ContentDisposition(dispositionType: String, parameters: Map[CIString, String])

object ContentDisposition {

  def getFileName[F[_]](part: Part[F]): Option[String] =
    part.headers.get[ContentDisposition].flatMap(_.parameters.get(ci"filename"))

  private[http4s] val mimeValue: Parser[String] = {
    val value = Parser.anyChar.repUntilAs[String](Parser.char(';').orElse(Parser.end))
    val qvalue =
      Rfc5234.dquote *> Parser.charsWhile(c => c != '"').string <* Rfc5234.dquote
    qvalue.orElse(value)
  }

  // --- taken from http4s (v0.23.6) with modification; Licensed under Apache License 2.0

  def parse(s: String): ParseResult[ContentDisposition] =
    fromParser(parser, "Invalid Content-Disposition header")(s)

  private def fromParser[A](parser: Parser0[A], errorMessage: => String)(
      s: String
  ): ParseResult[A] =
    try parser.parseAll(s).leftMap(e => ParseFailure(errorMessage, e.toString))
    catch { case p: ParseFailure => p.asLeft[A] }

  /* ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z */
  private[this] val alpha: Parser[Char] =
    Parser
      .charIn(0x41.toChar to 0x5a.toChar)
      .orElse(Parser.charIn(0x61.toChar to 0x7a.toChar))

  /* DIGIT          =  %x30-39
   *                       ; 0-9 */
  private[this] val digit: Parser[Char] =
    Parser.charIn(0x30.toChar to 0x39.toChar)

  /* The spec references RFC2234, which is 0-9A-F, but it also
   * explicitly permits lowercase. */
  private[this] val hexdig: Parser[Char] =
    digit.orElse(Parser.charIn("ABCDEFabcdef"))

  private[http4s] object Rfc7230 {
    /* `tchar = "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "." /
     *  "^" / "_" / "`" / "|" / "~" / DIGIT / ALPHA`
     */
    val tchar: Parser[Char] = Parser.charIn("!#$%&'*+-.^_`|~").orElse(digit).orElse(alpha)

    /* `token = 1*tchar` */
    val token: Parser[String] = tchar.rep.string

    val htab: Parser[Unit] =
      Parser.char('\t')

    val sp: Parser[Unit] =
      Parser.char(' ')

    /* `OWS = *( SP / HTAB )` */
    val ows: Parser0[Unit] = sp.orElse(htab).rep0.void

  }
  private[http4s] def makeParser(paramValueParser: Parser[String]) = {
    sealed trait ValueChar
    case class AsciiChar(c: Char) extends ValueChar
    case class EncodedChar(a: Char, b: Char) extends ValueChar

    val attrChar = alpha
      .orElse(digit)
      .orElse(Parser.charIn('!', '#', '$', '&', '+', '-', '.', '^', '_', '`', '|', '~'))
      .map { (a: Char) =>
        AsciiChar(a)
      }
    val pctEncoded = (Parser.string("%") *> hexdig ~ hexdig).map {
      case (a: Char, b: Char) => EncodedChar(a, b)
    }
    val valueChars = attrChar.orElse(pctEncoded).rep
    val language =
      (Parser.string(Rfc5234.alpha.rep) ~ (Parser.char('-') *> alpha.rep(1)).?).string
    val charset: Parser[Charset] =
      Parser.oneOf(
        Parser.ignoreCase("UTF-8").as(StandardCharsets.UTF_8) ::
          Parser.ignoreCase("ISO-8859-1").as(StandardCharsets.ISO_8859_1) ::
          Parser.ignoreCase("US-ASCII").as(StandardCharsets.US_ASCII) ::
          Nil
      )
    val extValue = (Rfc5234.dquote *> Parser.charsWhile0(
      CharPredicate.All -- '"'
    ) <* Rfc5234.dquote) | (charset.? ~ (Parser.string("'") *> language.? <* Parser
      .string(
        "'"
      )) ~ valueChars).map { case ((charset, _), values) =>
      values
        .map {
          case EncodedChar(a: Char, b: Char) =>
            val charByte = (Character.digit(a, 16) << 4) + Character.digit(b, 16)
            new String(Array(charByte.toByte), charset.getOrElse(StandardCharsets.UTF_8))
          case AsciiChar(a) => a.toString
        }
        .toList
        .mkString
    }

    val parameter = for {
      tok <- Rfc7230.token <* Parser.string("=") <* Rfc7230.ows
      v <- if (tok.endsWith("*")) extValue else paramValueParser
    } yield (CIString(tok), v)

    (Rfc7230.token ~ (Parser.string(";") *> Rfc7230.ows *> parameter).rep0).map {
      case (token: String, params: List[(CIString, String)]) =>
        ContentDisposition(token, params.toMap)
    }
  }

  private val parser = makeParser(mimeValue)
  // private val origParser = makeParser(Rfc7230.token | Rfc7230.quotedString)

  implicit val headerInstance: Header[ContentDisposition, Header.Single] = {
    val oh = `Content-Disposition`.headerInstance
    Header.createRendered(
      oh.name,
      v => oh.value(`Content-Disposition`(v.dispositionType, v.parameters)),
      parse
    )
  }
}
