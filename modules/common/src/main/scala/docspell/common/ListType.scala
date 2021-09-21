/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList

import io.circe.{Decoder, Encoder}

sealed trait ListType { self: Product =>
  def name: String =
    productPrefix.toLowerCase
}

object ListType {

  case object Whitelist extends ListType
  val whitelist: ListType = Whitelist

  case object Blacklist extends ListType
  val blacklist: ListType = Blacklist

  val all: NonEmptyList[ListType] = NonEmptyList.of(Whitelist, Blacklist)

  def fromString(name: String): Either[String, ListType] =
    all.find(_.name.equalsIgnoreCase(name)).toRight(s"Unknown list type: $name")

  def unsafeFromString(name: String): ListType =
    fromString(name).fold(sys.error, identity)

  implicit val jsonEncoder: Encoder[ListType] =
    Encoder.encodeString.contramap(_.name)

  implicit val jsonDecoder: Decoder[ListType] =
    Decoder.decodeString.emap(fromString)
}
