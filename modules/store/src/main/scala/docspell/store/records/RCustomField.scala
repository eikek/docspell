/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RCustomField(
    id: Ident,
    name: Ident,
    label: Option[String],
    cid: Ident,
    ftype: CustomFieldType,
    created: Timestamp
)

object RCustomField {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "custom_field"

    val id      = Column[Ident]("id", this)
    val name    = Column[Ident]("name", this)
    val label   = Column[String]("label", this)
    val cid     = Column[Ident]("cid", this)
    val ftype   = Column[CustomFieldType]("ftype", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, name, label, cid, ftype, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(value: RCustomField): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${value.id},${value.name},${value.label},${value.cid},${value.ftype},${value.created}"
    )

  def exists(fname: Ident, coll: Ident): ConnectionIO[Boolean] =
    run(select(count(T.id)), from(T), T.name === fname && T.cid === coll)
      .query[Int]
      .unique
      .map(_ > 0)

  def findById(fid: Ident, coll: Ident): ConnectionIO[Option[RCustomField]] =
    run(select(T.all), from(T), T.id === fid && T.cid === coll).query[RCustomField].option

  def findByIdOrName(idOrName: Ident, coll: Ident): ConnectionIO[Option[RCustomField]] =
    Select(
      select(T.all),
      from(T),
      T.cid === coll && (T.id === idOrName || T.name === idOrName)
    ).build.query[RCustomField].option

  def deleteById(fid: Ident, coll: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === fid && T.cid === coll)

  def findAll(coll: Ident): ConnectionIO[Vector[RCustomField]] =
    run(select(T.all), from(T), T.cid === coll).query[RCustomField].to[Vector]

  def update(value: RCustomField): ConnectionIO[Int] =
    DML
      .update(
        T,
        T.id === value.id && T.cid === value.cid,
        DML.set(
          T.name.setTo(value.name),
          T.label.setTo(value.label),
          T.ftype.setTo(value.ftype)
        )
      )

  def setValue(f: RCustomField, item: Ident, fval: String): ConnectionIO[Int] =
    for {
      n <- RCustomFieldValue.updateValue(f.id, item, fval)
      k <-
        if (n == 0)
          Ident
            .randomId[ConnectionIO]
            .flatMap(nId =>
              RCustomFieldValue
                .insert(RCustomFieldValue(nId, item, f.id, fval))
            )
        else 0.pure[ConnectionIO]
    } yield n + k

}
