/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.security.SecureRandom
import java.util.UUID

import cats.Eq
import cats.Order
import cats.effect.Sync
import cats.implicits._

import io.circe.{Decoder, Encoder}
import scodec.bits.ByteVector

case class Ident(id: String) {
  def isEmpty: Boolean =
    id.trim.isEmpty

  def nonEmpty: Boolean =
    !isEmpty

  def /(next: Ident): Ident =
    new Ident(id + Ident.concatChar + next.id)

  def /(next: Number): Ident =
    new Ident(id + Ident.concatChar + next)

  def take(n: Int): Ident =
    new Ident(id.take(n))
}

object Ident {
  private val concatChar = '.'
  implicit val identEq: Eq[Ident] =
    Eq.by(_.id)

  // Note, the slash *must not* be part of valid characters
  val chars: Set[Char] = (('A' to 'Z') ++ ('a' to 'z') ++ ('0' to '9') ++ "-_.@").toSet

  def randomUUID[F[_]: Sync]: F[Ident] =
    Sync[F].delay(unsafe(UUID.randomUUID.toString))

  def randomId[F[_]: Sync]: F[Ident] =
    Sync[F].delay {
      val random = new SecureRandom()
      val buffer = new Array[Byte](32)
      random.nextBytes(buffer)
      unsafe(ByteVector.view(buffer).toBase58.grouped(11).mkString("-"))
    }

  def apply(str: String): Either[String, Ident] =
    fromString(str)

  def fromString(s: String): Either[String, Ident] =
    if (s.forall(chars.contains)) Right(new Ident(s))
    else Left(s"Invalid identifier: '$s'. Allowed chars: ${chars.toList.sorted.mkString}")

  def fromBytes(bytes: ByteVector): Ident =
    unsafe(bytes.toBase58)

  def fromByteArray(bytes: Array[Byte]): Ident =
    fromBytes(ByteVector.view(bytes))

  def unsafe(s: String): Ident =
    fromString(s) match {
      case Right(id) => id
      case Left(err) => sys.error(err)
    }

  def unapply(arg: String): Option[Ident] =
    fromString(arg).toOption

  implicit val encodeIdent: Encoder[Ident] =
    Encoder.encodeString.contramap(_.id)

  implicit val decodeIdent: Decoder[Ident] =
    Decoder.decodeString.emap(Ident.fromString)

  implicit val order: Order[Ident] =
    Order.by(_.id)

  implicit val ordering: Ordering[Ident] =
    Ordering.by(_.id)
}
