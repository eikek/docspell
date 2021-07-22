/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

import java.nio.charset.Charset
import java.nio.charset.StandardCharsets

import cats.effect._
import fs2.{Chunk, Pipe, Stream}

import scodec.bits.ByteVector

final case class Binary[F[_]](name: String, mime: MimeType, data: Stream[F, Byte]) {

  def withMime(mime: MimeType): Binary[F] =
    copy(mime = mime)
}

object Binary {

  def apply[F[_]](name: String, data: Stream[F, Byte]): Binary[F] =
    Binary[F](name, MimeType.octetStream, data)

  def utf8[F[_]](name: String, content: String): Binary[F] =
    Binary[F](
      name,
      MimeType.octetStream,
      Stream.emit(content).through(fs2.text.utf8Encode)
    )

  def text[F[_]](name: String, content: String): Binary[F] =
    utf8(name, content).withMime(MimeType.plain.withUtf8Charset)

  def text[F[_]](name: String, content: ByteVector, cs: Charset): Binary[F] =
    Binary(name, MimeType.plain.withCharset(cs), Stream.chunk(Chunk.byteVector(content)))

  def html[F[_]](name: String, content: String): Binary[F] =
    utf8(name, content).withMime(MimeType.html.withUtf8Charset)

  def html[F[_]](name: String, content: ByteVector, cs: Charset): Binary[F] =
    Binary(name, MimeType.html.withCharset(cs), Stream.chunk(Chunk.byteVector(content)))

  def decode[F[_]](cs: Charset): Pipe[F, Byte, String] =
    if (cs == StandardCharsets.UTF_8)
      fs2.text.utf8Decode
    else
      util.decode[F](cs)

  def loadAllBytes[F[_]: Sync](data: Stream[F, Byte]): F[ByteVector] =
    data.chunks.map(_.toByteVector).compile.fold(ByteVector.empty)((r, e) => r ++ e)

  // This is a copy from org.http4s.util
  // Http4s is licensed under the Apache License 2.0
  private object util {
    import fs2._
    import java.nio._

    private val utf8Bom: Chunk[Byte] = Chunk(0xef.toByte, 0xbb.toByte, 0xbf.toByte)

    def decode[F[_]](charset: Charset): Pipe[F, Byte, String] = {
      val decoder         = charset.newDecoder
      val maxCharsPerByte = math.ceil(decoder.maxCharsPerByte().toDouble).toInt
      val avgBytesPerChar = math.ceil(1.0 / decoder.averageCharsPerByte().toDouble).toInt
      val charBufferSize  = 128

      _.repeatPull[String] {
        _.unconsN(charBufferSize * avgBytesPerChar, allowFewer = true).flatMap {
          case None =>
            val charBuffer = CharBuffer.allocate(1)
            decoder.decode(ByteBuffer.allocate(0), charBuffer, true)
            decoder.flush(charBuffer)
            val outputString = charBuffer.flip().toString
            if (outputString.isEmpty) Pull.done.as(None)
            else Pull.output1(outputString).as(None)
          case Some((chunk, stream)) =>
            if (chunk.nonEmpty) {
              val chunkWithoutBom = skipByteOrderMark(chunk)
              val bytes           = chunkWithoutBom.toArray
              val byteBuffer      = ByteBuffer.wrap(bytes)
              val charBuffer      = CharBuffer.allocate(bytes.length * maxCharsPerByte)
              decoder.decode(byteBuffer, charBuffer, false)
              val nextStream = stream.consChunk(Chunk.byteBuffer(byteBuffer.slice()))
              Pull.output1(charBuffer.flip().toString).as(Some(nextStream))
            } else
              Pull.output(Chunk.empty[String]).as(Some(stream))
        }
      }
    }

    private def skipByteOrderMark[F[_]](chunk: Chunk[Byte]): Chunk[Byte] =
      if (chunk.size >= 3 && chunk.take(3) == utf8Bom)
        chunk.drop(3)
      else chunk

  }
}
