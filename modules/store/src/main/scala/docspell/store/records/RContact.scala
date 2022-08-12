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

case class RContact(
    contactId: Ident,
    value: String,
    kind: ContactKind,
    personId: Option[Ident],
    orgId: Option[Ident],
    created: Timestamp
) {}

object RContact {

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "contact"

    val contactId = Column[Ident]("contactid", this)
    val value = Column[String]("value_", this)
    val kind = Column[ContactKind]("kind", this)
    val personId = Column[Ident]("pid", this)
    val orgId = Column[Ident]("oid", this)
    val created = Column[Timestamp]("created", this)
    val all = NonEmptyList.of[Column[_]](contactId, value, kind, personId, orgId, created)
  }

  private val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RContact): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.contactId},${v.value},${v.kind},${v.personId},${v.orgId},${v.created}"
    )

  def update(v: RContact): ConnectionIO[Int] =
    DML.update(
      T,
      T.contactId === v.contactId,
      DML.set(
        T.value.setTo(v.value),
        T.kind.setTo(v.kind),
        T.personId.setTo(v.personId),
        T.orgId.setTo(v.orgId)
      )
    )

  def delete(v: RContact): ConnectionIO[Int] =
    DML.delete(T, T.contactId === v.contactId)

  def deleteOrg(oid: Ident): ConnectionIO[Int] =
    DML.delete(T, T.orgId === oid)

  def deletePerson(pid: Ident): ConnectionIO[Int] =
    DML.delete(T, T.personId === pid)

  def findById(id: Ident): ConnectionIO[Option[RContact]] = {
    val sql = run(select(T.all), from(T), T.contactId === id)
    sql.query[RContact].option
  }

  def findAllPerson(pid: Ident): ConnectionIO[Vector[RContact]] = {
    val sql = run(select(T.all), from(T), T.personId === pid)
    sql.query[RContact].to[Vector]
  }

  def findAllOrg(oid: Ident): ConnectionIO[Vector[RContact]] = {
    val sql = run(select(T.all), from(T), T.orgId === oid)
    sql.query[RContact].to[Vector]
  }
}
