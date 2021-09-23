/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.files

import java.io.BufferedInputStream
import java.nio.charset.Charset
import java.nio.file.Files

import scala.jdk.CollectionConverters._
import scala.util.Using

import cats.effect.Sync
import cats.implicits._
import fs2.Stream
import fs2.io.file.Path

import docspell.common._

import org.apache.tika.config.TikaConfig
import org.apache.tika.metadata.{HttpHeaders, Metadata, TikaCoreProperties}
import org.apache.tika.mime.MediaType
import org.apache.tika.parser.txt.Icu4jEncodingDetector
import scodec.bits.ByteVector

object TikaMimetype {
  private val tika = new TikaConfig().getDetector

  private def convert(mt: MediaType): MimeType =
    Option(mt) match {
      case Some(_) =>
        val cs = mt.getParameters.asScala.toMap.get("charset").getOrElse("unknown")
        val primary = mt.getType
        val sub = mt.getSubtype
        normalize(MimeType(primary, sub, None).withCharsetName(cs))
      case None =>
        MimeType.octetStream
    }

  private def makeMetadata(hint: MimeTypeHint): Metadata = {
    val md = new Metadata
    hint.filename.foreach(md.set(TikaCoreProperties.RESOURCE_NAME_KEY, _))
    hint.advertised.foreach(md.set(HttpHeaders.CONTENT_TYPE, _))
    md
  }

  private def normalize(in: MimeType): MimeType =
    in match {
      case MimeType(_, sub, cs) if sub contains "xhtml" =>
        MimeType.html.copy(charset = cs)
      case _ => in
    }

  private def fromBytes(bv: Array[Byte], hint: MimeTypeHint): MimeType = {
    val mt = convert(
      tika.detect(new java.io.ByteArrayInputStream(bv), makeMetadata(hint))
    )
    if (mt.primary == "text")
      charsetFromBytes(bv, hint) match {
        case Some(cs) =>
          mt.withCharset(cs)
        case None =>
          mt
      }
    else mt
  }

  private def charsetFromBytes(bv: Array[Byte], hint: MimeTypeHint): Option[Charset] =
    Either
      .catchNonFatal {
        val cd = new Icu4jEncodingDetector()
        val md = makeMetadata(hint)
        Option(cd.detect(new java.io.ByteArrayInputStream(bv), md))
      }
      .toOption
      .flatten

  def detectCharset[F[_]: Sync](data: Stream[F, Byte], hint: MimeTypeHint) =
    data.take(8000).compile.toVector.map(bytes => charsetFromBytes(bytes.toArray, hint))

  def detect[F[_]: Sync](data: Stream[F, Byte], hint: MimeTypeHint): F[MimeType] =
    data.take(64).compile.toVector.map(bytes => fromBytes(bytes.toArray, hint))

  def detect(data: ByteVector, hint: MimeTypeHint): MimeType =
    fromBytes(data.toArray, hint)

  def resolve[F[_]: Sync](dt: DataType, data: Stream[F, Byte]): F[MimeType] =
    dt match {
      case DataType.Exact(mt) =>
        mt.charset match {
          case None if mt.primary == "text" =>
            detectCharset[F](data, MimeTypeHint.advertised(mt))
              .map {
                case Some(cs) => mt.withCharset(cs)
                case None     => mt
              }
          case _ => mt.pure[F]
        }
      case DataType.Hint(hint) =>
        TikaMimetype.detect(data, hint)
    }

  def detect[F[_]: Sync](file: Path): F[MimeType] =
    Sync[F].delay {
      val hint = MimeTypeHint.filename(file.fileName.toString)
      Using(new BufferedInputStream(Files.newInputStream(file.toNioPath), 64)) { in =>
        convert(tika.detect(in, makeMetadata(hint)))
      }.toEither
    }.rethrow
}
