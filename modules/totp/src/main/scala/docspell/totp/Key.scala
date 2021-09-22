/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.totp

import java.security.{Key => JKey}
import javax.crypto.KeyGenerator
import javax.crypto.spec.SecretKeySpec

import cats.effect._

import io.circe.generic.semiauto
import io.circe.{Decoder, Encoder}
import scodec.bits.ByteVector

final case class Key(data: ByteVector, mac: Mac) {
  def toJavaKey: JKey =
    new SecretKeySpec(data.toArray, mac.identifier)

  /** Renders the mac and data into one string which can be consumed by `fromString` */
  def asString: String =
    s"${mac.identifier}::${data.toBase32}"
}

object Key {

  def fromSecretKey(sk: JKey): Either[String, Key] =
    for {
      mac <- Mac.fromString(sk.getAlgorithm)
      key = Key(ByteVector.view(sk.getEncoded), mac)
    } yield key

  def generate[F[_]: Sync](mac: Mac): F[Key] = Sync[F].delay {
    val jkey = generateJavaKey(mac)
    Key(ByteVector.view(jkey.getEncoded), mac)
  }

  def fromString(str: String): Either[String, Key] = {
    val (macStr, dataStr) = str.span(_ != ':')
    if (dataStr.isEmpty) Left(s"No separator found in key string: $str")
    else
      for {
        mac <- Mac.fromString(macStr)
        data <- ByteVector.fromBase32Descriptive(dataStr.dropWhile(_ == ':'))
      } yield Key(data, mac)
  }

  def unsafeFromString(str: String): Key =
    fromString(str).fold(sys.error, identity)

  private[totp] def generateJavaKey(mac: Mac): JKey = {
    val keyGen = KeyGenerator.getInstance(mac.identifier)
    keyGen.init(mac.keyLengthBits)
    keyGen.generateKey()
  }

  implicit val jsonEncoder: Encoder[Key] =
    Codec.jsonEncoder

  implicit val jsonDecoder: Decoder[Key] =
    Codec.jsonDecoder

  private object Codec {
    implicit val byteVectorEncoder: Encoder[ByteVector] =
      Encoder.encodeString.contramap(_.toBase32)

    implicit val byteVectorDecoder: Decoder[ByteVector] =
      Decoder.decodeString.emap(s => ByteVector.fromBase32Descriptive(s))

    val jsonEncoder: Encoder[Key] =
      semiauto.deriveEncoder[Key]

    val jsonDecoder: Decoder[Key] =
      semiauto.deriveDecoder[Key]
  }
}
