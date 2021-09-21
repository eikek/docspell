/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.Eq
import cats.data.{NonEmptyList => Nel}
import fs2.Stream

import docspell.common.{IdRef, _}
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class ROrganization(
    oid: Ident,
    cid: Ident,
    name: String,
    street: String,
    zip: String,
    city: String,
    country: String,
    notes: Option[String],
    created: Timestamp,
    updated: Timestamp,
    shortName: Option[String],
    use: OrgUse
) {}

object ROrganization {
  implicit val orgEq: Eq[ROrganization] =
    Eq.by[ROrganization, Ident](_.oid)

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "organization"

    val oid       = Column[Ident]("oid", this)
    val cid       = Column[Ident]("cid", this)
    val name      = Column[String]("name", this)
    val street    = Column[String]("street", this)
    val zip       = Column[String]("zip", this)
    val city      = Column[String]("city", this)
    val country   = Column[String]("country", this)
    val notes     = Column[String]("notes", this)
    val created   = Column[Timestamp]("created", this)
    val updated   = Column[Timestamp]("updated", this)
    val shortName = Column[String]("short_name", this)
    val use       = Column[OrgUse]("org_use", this)
    val all =
      Nel.of[Column[_]](
        oid,
        cid,
        name,
        street,
        zip,
        city,
        country,
        notes,
        created,
        updated,
        shortName,
        use
      )
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: ROrganization): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.oid},${v.cid},${v.name},${v.street},${v.zip},${v.city},${v.country},${v.notes},${v.created},${v.updated},${v.shortName},${v.use}"
    )

  def update(v: ROrganization): ConnectionIO[Int] = {
    def sql(now: Timestamp) =
      DML.update(
        T,
        T.oid === v.oid && T.cid === v.cid,
        DML.set(
          T.cid.setTo(v.cid),
          T.name.setTo(v.name),
          T.street.setTo(v.street),
          T.zip.setTo(v.zip),
          T.city.setTo(v.city),
          T.country.setTo(v.country),
          T.notes.setTo(v.notes),
          T.updated.setTo(now),
          T.shortName.setTo(v.shortName),
          T.use.setTo(v.use)
        )
      )
    for {
      now <- Timestamp.current[ConnectionIO]
      n   <- sql(now)
    } yield n
  }

  def existsByName(coll: Ident, oname: String): ConnectionIO[Boolean] =
    run(select(count(T.oid)), from(T), T.cid === coll && T.name === oname)
      .query[Int]
      .unique
      .map(_ > 0)

  def findById(id: Ident): ConnectionIO[Option[ROrganization]] = {
    val sql = run(select(T.all), from(T), T.cid === id)
    sql.query[ROrganization].option
  }

  def find(coll: Ident, orgName: String): ConnectionIO[Option[ROrganization]] = {
    val sql = run(select(T.all), from(T), T.cid === coll && T.name === orgName)
    sql.query[ROrganization].option
  }

  def findLike(
      coll: Ident,
      orgName: String,
      use: Nel[OrgUse]
  ): ConnectionIO[Vector[IdRef]] =
    run(
      select(T.oid, T.name),
      from(T),
      T.cid === coll && (T.name.like(orgName) || T.shortName.like(orgName)) && T.use.in(
        use
      )
    )
      .query[IdRef]
      .to[Vector]

  def findLike(
      coll: Ident,
      contactKind: ContactKind,
      value: String
  ): ConnectionIO[Vector[IdRef]] = {
    val c = RContact.as("c")
    val o = ROrganization.as("o")
    runDistinct(
      select(o.oid, o.name),
      from(o).innerJoin(c, c.orgId === o.oid),
      where(
        o.cid === coll,
        c.kind === contactKind,
        c.value.like(value)
      )
    ).query[IdRef].to[Vector]
  }

  def findAll(
      coll: Ident,
      order: Table => Column[_]
  ): Stream[ConnectionIO, ROrganization] = {
    val sql = Select(select(T.all), from(T), T.cid === coll).orderBy(order(T))
    sql.build.query[ROrganization].stream
  }

  def findAllRef(
      coll: Ident,
      nameQ: Option[String],
      order: Table => Nel[OrderBy]
  ): ConnectionIO[Vector[IdRef]] = {
    val nameFilter = nameQ.map(s =>
      T.name.like(s"%${s.toLowerCase}%") || T.shortName.like(s"%${s.toLowerCase}%")
    )
    val sql = Select(select(T.oid, T.name), from(T), T.cid === coll &&? nameFilter)
      .orderBy(order(T))
    sql.build.query[IdRef].to[Vector]
  }

  def delete(id: Ident, coll: Ident): ConnectionIO[Int] =
    DML.delete(T, T.oid === id && T.cid === coll)
}
