/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.config

import cats.data.NonEmptyList

sealed trait FtsType {
  def name: String
}

object FtsType {
  case object Solr extends FtsType { val name = "solr" }
  case object PostgreSQL extends FtsType { val name = "postgresql" }

  val all: NonEmptyList[FtsType] =
    NonEmptyList.of(Solr, PostgreSQL)

  def fromName(str: String): Either[String, FtsType] =
    all.find(_.name.equalsIgnoreCase(str)).toRight(s"Unknown fts type: $str")

  def unsafeFromName(str: String): FtsType =
    fromName(str).fold(sys.error, identity)
}
