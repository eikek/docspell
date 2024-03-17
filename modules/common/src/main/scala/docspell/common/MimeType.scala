/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.nio.charset.Charset
import java.nio.charset.StandardCharsets

import scala.util.Try

import cats.data.NonEmptyList

import docspell.common.syntax.all._

import io.circe.{Decoder, Encoder}

/** A MIME Type impl with just enough features for the use here. */
case class MimeType(primary: String, sub: String, charset: Option[Charset]) {

  def withCharset(cs: Charset): MimeType =
    copy(charset = Some(cs))

  def withUtf8Charset: MimeType =
    withCharset(StandardCharsets.UTF_8)

  def withCharsetName(csName: String): MimeType =
    if (Try(Charset.isSupported(csName)).getOrElse(false))
      withCharset(Charset.forName(csName))
    else this

  def charsetOrUtf8: Charset =
    charset.getOrElse(StandardCharsets.UTF_8)

  def baseType: MimeType =
    if (charset.isEmpty) this else copy(charset = None)

  def asString: String =
    charset match {
      case Some(cs) =>
        s"$primary/$sub; charset=\"${cs.name()}\""
      case None =>
        s"$primary/$sub"
    }

  def matches(other: MimeType): Boolean =
    primary == other.primary &&
      (sub == other.sub || sub == "*")
}

object MimeType {

  def application(sub: String): MimeType =
    MimeType("application", sub, None)

  def text(sub: String): MimeType =
    MimeType("text", sub, None)

  def image(sub: String): MimeType =
    MimeType("image", sub, None)

  def parse(str: String): Either[String, MimeType] =
    Parser.parse(str)

  def unsafe(str: String): MimeType =
    parse(str).throwLeft

  val octetStream = application("octet-stream")
  val pdf = application("pdf")
  val zip = application("zip")
  val png = image("png")
  val jpeg = image("jpeg")
  val tiff = image("tiff")
  val html = text("html")
  val plain = text("plain")
  val json = application("json")
  val emls = NonEmptyList.of(
    MimeType("message", "rfc822", None),
    application("mbox")
  )

  object PdfMatch {
    def unapply(mt: MimeType): Option[MimeType] =
      Some(mt).filter(_.matches(pdf))
  }

  object TextAllMatch {
    def unapply(mt: MimeType): Option[MimeType] =
      Some(mt).filter(_.primary == "text")
  }

  object HtmlMatch {
    def unapply(mt: MimeType): Option[MimeType] =
      if (
        (mt.primary == "text" || mt.primary == "application") && mt.sub.contains("html")
      ) Some(mt)
      else None
  }

  object NonHtmlText {
    def unapply(mt: MimeType): Option[MimeType] =
      if (mt.primary == "text" && !mt.sub.contains("html")) Some(mt)
      else None
  }

  object ZipMatch {
    def unapply(mt: MimeType): Option[MimeType] =
      Some(mt).filter(_.matches(zip))
  }

  /** Only jpeg, png and tiff */
  object ImageMatch {
    val all = Set(MimeType.jpeg, MimeType.png, MimeType.tiff)

    def unapply(m: MimeType): Option[MimeType] =
      Some(m).map(_.baseType).filter(all.contains)
  }

  object EmailMatch {
    def unapply(mt: MimeType): Option[MimeType] =
      if (emls.exists(mt.matches(_))) Some(mt)
      else None
  }

  implicit val jsonEncoder: Encoder[MimeType] =
    Encoder.encodeString.contramap(_.asString)

  implicit val jsonDecoder: Decoder[MimeType] =
    Decoder.decodeString.emap(parse)

  private object Parser {
    def parse(s: String): Either[String, MimeType] =
      mimeType(s).map(_._1)

    type Result[A] = Either[String, (A, String)]
    type P[A] = String => Result[A]

    private[this] val tokenExtraChars = "+-$%*._~".toSet

    private def seq[A, B, C](pa: P[A], pb: P[B])(f: (A, B) => C): P[C] =
      in =>
        pa(in) match {
          case Right((a, resta)) =>
            pb(resta) match {
              case Right((b, restb)) =>
                Right((f(a, b), restb))
              case left =>
                left.asInstanceOf[Result[C]]
            }
          case left =>
            left.asInstanceOf[Result[C]]
        }

    private def takeWhile(p: Char => Boolean): P[String] =
      in => {
        val (prefix, suffix) = in.span(p)
        Right((prefix.trim, suffix.drop(1).trim))
      }

    private def check[A](p: P[A], test: A => Boolean, err: => String): P[A] =
      in =>
        p(in) match {
          case r @ Right((a, _)) =>
            if (test(a)) r else Left(err)
          case left =>
            left
        }

    // https://datatracker.ietf.org/doc/html/rfc7230#section-3.2.6
    private def isToken(s: String): Boolean =
      s.nonEmpty && s.forall(c => c.isLetterOrDigit || tokenExtraChars.contains(c))

    private val baseType: P[MimeType] = {
      val primary = check(
        takeWhile(_ != '/'),
        isToken,
        "Primary type must be non-empty and contain valid characters"
      )
      val sub = check(
        takeWhile(_ != ';'),
        isToken,
        "Subtype must be non-empty and contain valid characters"
      )
      seq(primary, sub)((p, s) => MimeType(p.toLowerCase, s.toLowerCase, None))
    }

    // https://datatracker.ietf.org/doc/html/rfc2046#section-4.1.2
    private val charset: P[Option[Charset]] = in =>
      in.trim.toLowerCase.indexOf("charset=") match {
        case -1 => Right((None, in))
        case n =>
          val csValueStart = in.substring(n + "charset=".length).trim
          val csName = csValueStart.indexOf(';') match {
            case -1 => unquote(csValueStart).trim
            case n2 => unquote(csValueStart.substring(0, n2)).trim
          }
          if (Charset.isSupported(csName)) Right((Some(Charset.forName(csName)), ""))
          else Right((None, ""))
      }

    private val mimeType =
      seq(baseType, charset)((bt, cs) => bt.copy(charset = cs))

    private def unquote(s: String): String = {
      val len = s.length
      if (len == 0 || len == 1) s
      else {
        if (s.charAt(0) == '"' && s.charAt(len - 1) == '"')
          unquote(s.substring(1, len - 1))
        else s
      }
    }
  }
}
