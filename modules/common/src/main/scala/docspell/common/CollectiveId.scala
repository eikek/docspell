/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.{Decoder, Encoder}

final class CollectiveId(val value: Long) extends AnyVal {

  def valueAsString: String =
    value.toString

  def valueAsIdent: Ident =
    Ident.unsafe(valueAsString)

  override def toString =
    s"CollectiveId($value)"
}

object CollectiveId {
  val unknown: CollectiveId = CollectiveId(-1)

  def apply(n: Long): CollectiveId = new CollectiveId(n)

  def fromString(str: String): Either[String, CollectiveId] =
    str.trim.toLongOption.map(CollectiveId(_)).toRight(s"Invalid collective id: $str")

  def unsafeFromString(str: String): CollectiveId =
    fromString(str).fold(sys.error, identity)

  implicit val jsonEncoder: Encoder[CollectiveId] =
    Encoder.encodeLong.contramap(_.value)
  implicit val jsonDecoder: Decoder[CollectiveId] =
    Decoder.decodeLong.map(CollectiveId.apply)
}
