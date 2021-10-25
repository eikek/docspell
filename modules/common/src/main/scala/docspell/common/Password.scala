/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.nio.charset.StandardCharsets

import cats.effect.Sync
import cats.implicits._

import io.circe.{Decoder, Encoder}
import scodec.bits.ByteVector

final class Password(val pass: String) extends AnyVal {

  def isEmpty: Boolean = pass.isEmpty
  def nonEmpty: Boolean = pass.nonEmpty
  def length: Int = pass.length

  def asByteVector: ByteVector =
    ByteVector.view(pass.getBytes(StandardCharsets.UTF_8))

  override def toString: String =
    if (pass.isEmpty) "<empty>" else "***"

  def compare(other: Password): Boolean =
    this.pass.zip(other.pass).forall { case (a, b) => a == b } &&
      this.nonEmpty && this.length == other.length
}

object Password {

  val empty = Password("")

  def apply(pass: String): Password =
    new Password(pass)

  def generate[F[_]: Sync]: F[Password] =
    for {
      id <- Ident.randomId[F]
      pass = id.id.take(11)
    } yield Password(pass)

  implicit val passwordEncoder: Encoder[Password] =
    Encoder.encodeString.contramap(_.pass)

  implicit val passwordDecoder: Decoder[Password] =
    Decoder.decodeString.map(Password(_))

}
