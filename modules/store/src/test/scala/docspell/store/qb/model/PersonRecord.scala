/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb.model

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.qb._

case class PersonRecord(id: Long, name: String, created: Timestamp)

object PersonRecord {

  final case class Table(alias: Option[String]) extends TableDef {

    val tableName = "person"

    val id = Column[Long]("id", this)
    val name = Column[String]("name", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, name, created)
  }

  def as(alias: String): Table =
    Table(Some(alias))

}
