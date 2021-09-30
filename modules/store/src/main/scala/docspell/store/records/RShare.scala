/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.query.ItemQuery
import docspell.store.qb._

final case class RShare(
    id: Ident,
    cid: Ident,
    query: ItemQuery,
    enabled: Boolean,
    password: Option[Password],
    publishedAt: Timestamp,
    publishedUntil: Timestamp,
    views: Int,
    lastAccess: Option[Timestamp]
) {}

object RShare {

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "item_share";

    val id = Column[Ident]("id", this)
    val cid = Column[Ident]("cid", this)
    val query = Column[ItemQuery]("query", this)
    val enabled = Column[Boolean]("enabled", this)
    val password = Column[Password]("password", this)
    val publishedAt = Column[Timestamp]("published_at", this)
    val publishedUntil = Column[Timestamp]("published_until", this)
    val views = Column[Int]("views", this)
    val lastAccess = Column[Timestamp]("last_access", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(
        id,
        cid,
        query,
        enabled,
        password,
        publishedAt,
        publishedUntil,
        views,
        lastAccess
      )
  }

  val T: Table = Table(None)
  def as(alias: String): Table = Table(Some(alias))

}
