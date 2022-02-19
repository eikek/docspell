/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import cats.Order
import cats.data.NonEmptyList

import io.circe.{Decoder, Encoder}

sealed trait Level { self: Product =>
  val name: String =
    productPrefix.toUpperCase

  val value: Double
}

object Level {
  case object Fatal extends Level {
    val value = 600.0
  }
  case object Error extends Level {
    val value = 500.0
  }
  case object Warn extends Level {
    val value = 400.0
  }
  case object Info extends Level {
    val value = 300.0
  }
  case object Debug extends Level {
    val value = 200.0
  }
  case object Trace extends Level {
    val value = 100.0
  }

  val all: NonEmptyList[Level] =
    NonEmptyList.of(Fatal, Error, Warn, Info, Debug, Trace)

  def fromString(str: String): Either[String, Level] = {
    val s = str.toUpperCase
    all.find(_.name == s).toRight(s"Invalid level name: $str")
  }

  implicit val order: Order[Level] =
    Order.by(_.value)

  implicit val jsonEncoder: Encoder[Level] =
    Encoder.encodeString.contramap(_.name)

  implicit val jsonDecoder: Decoder[Level] =
    Decoder.decodeString.emap(fromString)
}
