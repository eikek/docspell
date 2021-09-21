/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.Decoder
import io.circe.Encoder

final case class ByteSize(bytes: Long) {

  def toHuman: String =
    ByteSize.bytesToHuman(bytes)

  def <=(other: ByteSize) =
    bytes <= other.bytes

  def >=(other: ByteSize) =
    bytes >= other.bytes

  def >(other: ByteSize) =
    bytes > other.bytes

  def -(other: ByteSize) =
    ByteSize(bytes - other.bytes)

  def +(other: ByteSize) =
    ByteSize(bytes + other.bytes)
}

object ByteSize {

  val zero = ByteSize(0L)

  def bytesToHuman(bytes: Long): String =
    if (math.abs(bytes) < 1024 && bytes != Long.MinValue) s"${bytes}B"
    else {
      val k = bytes / 1024.0
      if (math.abs(k) < 1024) f"$k%.02fK"
      else {
        val m = k / 1024.0
        if (math.abs(m) < 1024) f"$m%.02fM"
        else f"${m / 1024.0}%.02fG"
      }
    }

  def parse(str: String): Either[String, ByteSize] =
    str.toLongOption
      .map(ByteSize.apply)
      .toRight(s"Not a valid size string: $str")
      .orElse(span(str.toLowerCase) match {
        case (num, "k") =>
          Right(ByteSize(math.round(num.toDouble * 1024)))
        case (num, "m") =>
          Right(ByteSize(math.round(num.toDouble * 1024 * 1024)))
        case (num, "g") =>
          Right(ByteSize(math.round(num.toDouble * 1024 * 1024 * 1024)))
        case _ =>
          Left(s"Invalid byte string: $str")
      })

  private def span(str: String): (String, String) =
    if (str.isEmpty) ("", "")
    else (str.init, str.last.toString)

  def unsafe(str: String): ByteSize =
    parse(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[ByteSize] =
    Decoder.decodeLong.map(ByteSize.apply)
  implicit val jsonEncoder: Encoder[ByteSize] =
    Encoder.encodeLong.contramap(_.bytes)
}
