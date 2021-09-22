/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RCustomFieldValue(
    id: Ident,
    itemId: Ident,
    field: Ident,
    value: String
)

object RCustomFieldValue {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "custom_field_value"

    val id = Column[Ident]("id", this)
    val itemId = Column[Ident]("item_id", this)
    val field = Column[Ident]("field", this)
    val value = Column[String]("field_value", this)

    val all = NonEmptyList.of[Column[_]](id, itemId, field, value)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(value: RCustomFieldValue): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${value.id},${value.itemId},${value.field},${value.value}"
    )

  def updateValue(
      fieldId: Ident,
      item: Ident,
      value: String
  ): ConnectionIO[Int] =
    DML.update(
      T,
      T.itemId === item && T.field === fieldId,
      DML.set(T.value.setTo(value))
    )

  def countField(fieldId: Ident): ConnectionIO[Int] =
    Select(count(T.id).s, from(T), T.field === fieldId).build.query[Int].unique

  def deleteByField(fieldId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.field === fieldId)

  def deleteByItem(item: Ident): ConnectionIO[Int] =
    DML.delete(T, T.itemId === item)

  def deleteValue(fieldId: Ident, items: NonEmptyList[Ident]): ConnectionIO[Int] =
    DML.delete(
      T,
      T.field === fieldId && T.itemId.in(items)
    )
}
