/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.nio.charset.Charset
import java.nio.charset.StandardCharsets

import cats.data.NonEmptyList

import docspell.common.syntax.all._

import io.circe.{Decoder, Encoder}

/** A MIME Type impl with just enough features for the use here.
  */
case class MimeType(primary: String, sub: String, params: Map[String, String]) {
  def withParam(name: String, value: String): MimeType =
    copy(params = params.updated(name, value))

  def withCharset(cs: Charset): MimeType =
    withParam("charset", cs.name())

  def withUtf8Charset: MimeType =
    withCharset(StandardCharsets.UTF_8)

  def resolveCharset: Option[Charset] =
    params.get("charset").flatMap { cs =>
      if (Charset.isSupported(cs)) Some(Charset.forName(cs))
      else None
    }

  def charsetOrUtf8: Charset =
    resolveCharset.getOrElse(StandardCharsets.UTF_8)

  def baseType: MimeType =
    if (params.isEmpty) this else copy(params = Map.empty)

  def asString: String =
    if (params.isEmpty) s"$primary/$sub"
    else {
      val parameters = params.toList.map(t => s"""${t._1}="${t._2}"""").mkString(";")
      s"$primary/$sub; $parameters"
    }

  def matches(other: MimeType): Boolean =
    primary == other.primary &&
      (sub == other.sub || sub == "*")
}

object MimeType {

  def application(sub: String): MimeType =
    MimeType("application", sub, Map.empty)

  def text(sub: String): MimeType =
    MimeType("text", sub, Map.empty)

  def image(sub: String): MimeType =
    MimeType("image", sub, Map.empty)

  def parse(str: String): Either[String, MimeType] = {
    def parsePrimary: Either[String, (String, String)] =
      str.indexOf('/') match {
        case -1 => Left(s"Invalid mediatype: $str")
        case n  => Right(str.take(n) -> str.drop(n + 1))
      }

    def parseSub(s: String): Either[String, (String, String)] =
      s.indexOf(';') match {
        case -1 => Right((s, ""))
        case n  => Right((s.take(n), s.drop(n)))
      }

    def parseParams(s: String): Map[String, String] =
      s.split(';')
        .map(_.trim)
        .filter(_.nonEmpty)
        .toList
        .flatMap(p =>
          p.split("=", 2).toList match {
            case a :: b :: Nil => Some((a, b))
            case _             => None
          }
        )
        .toMap

    for {
      pt <- parsePrimary
      st <- parseSub(pt._2)
      pa = parseParams(st._2)
    } yield MimeType(pt._1, st._1, pa)
  }

  def unsafe(str: String): MimeType =
    parse(str).throwLeft

  val octetStream = application("octet-stream")
  val pdf         = application("pdf")
  val zip         = application("zip")
  val png         = image("png")
  val jpeg        = image("jpeg")
  val tiff        = image("tiff")
  val html        = text("html")
  val plain       = text("plain")
  val emls = NonEmptyList.of(
    MimeType("message", "rfc822", Map.empty),
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
      Some(mt).filter(_.matches(html))
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
}
