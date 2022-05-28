/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store

import cats.data.NonEmptyList

import io.circe.{Decoder, Encoder}

sealed trait Db {
  def name: String
  def driverClass: String
}

object Db {

  case object PostgreSQL extends Db {
    val name = "postgresql"
    val driverClass = "org.postgresql.Driver"
  }

  case object MariaDB extends Db {
    val name = "mariadb"
    val driverClass = "org.mariadb.jdbc.Driver"
  }

  case object H2 extends Db {
    val name = "h2"
    val driverClass = "org.h2.Driver"
  }

  val all: NonEmptyList[Db] = NonEmptyList.of(PostgreSQL, MariaDB, H2)

  def fromString(str: String): Either[String, Db] =
    all.find(_.name.equalsIgnoreCase(str)).toRight(s"Unsupported db name: $str")

  def unsafeFromString(str: String): Db =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[Db] =
    Decoder.decodeString.emap(fromString)

  implicit val jsonEncoder: Encoder[Db] =
    Encoder.encodeString.contramap(_.name)
}
