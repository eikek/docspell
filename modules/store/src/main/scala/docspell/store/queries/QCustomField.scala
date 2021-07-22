/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.queries

import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records._

import doobie._

object QCustomField {
  private val f = RCustomField.as("f")
  private val v = RCustomFieldValue.as("v")

  case class CustomFieldData(field: RCustomField, usageCount: Int)

  def findAllLike(
      coll: Ident,
      nameQuery: Option[String]
  ): ConnectionIO[Vector[CustomFieldData]] =
    findFragment(coll, nameQuery, None).build.query[CustomFieldData].to[Vector]

  def findById(field: Ident, collective: Ident): ConnectionIO[Option[CustomFieldData]] =
    findFragment(collective, None, field.some).build.query[CustomFieldData].option

  private def findFragment(
      coll: Ident,
      nameQuery: Option[String],
      fieldId: Option[Ident]
  ): Select = {
    val nameFilter = nameQuery.map { q =>
      f.name.likes(q) || (f.label.isNotNull && f.label.like(q))
    }

    Select(
      f.all.map(_.s).append(count(v.id).as("num")),
      from(f)
        .leftJoin(v, f.id === v.field),
      f.cid === coll &&? nameFilter &&? fieldId.map(fid => f.id === fid),
      GroupBy(f.all)
    )
  }
}
