package docspell.store.records

import cats.Eq
import cats.data.NonEmptyList
import cats.effect._
import fs2.Stream

import docspell.common.{IdRef, _}
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RPerson(
    pid: Ident,
    cid: Ident,
    name: String,
    street: String,
    zip: String,
    city: String,
    country: String,
    notes: Option[String],
    concerning: Boolean,
    created: Timestamp,
    updated: Timestamp,
    oid: Option[Ident]
) {}

object RPerson {
  implicit val personEq: Eq[RPerson] =
    Eq.by(_.pid)

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "person"

    val pid        = Column[Ident]("pid", this)
    val cid        = Column[Ident]("cid", this)
    val name       = Column[String]("name", this)
    val street     = Column[String]("street", this)
    val zip        = Column[String]("zip", this)
    val city       = Column[String]("city", this)
    val country    = Column[String]("country", this)
    val notes      = Column[String]("notes", this)
    val concerning = Column[Boolean]("concerning", this)
    val created    = Column[Timestamp]("created", this)
    val updated    = Column[Timestamp]("updated", this)
    val oid        = Column[Ident]("oid", this)
    val all = NonEmptyList.of[Column[_]](
      pid,
      cid,
      name,
      street,
      zip,
      city,
      country,
      notes,
      concerning,
      created,
      updated,
      oid
    )
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RPerson): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.pid},${v.cid},${v.name},${v.street},${v.zip},${v.city},${v.country},${v.notes},${v.concerning},${v.created},${v.updated},${v.oid}"
    )

  def update(v: RPerson): ConnectionIO[Int] = {
    def sql(now: Timestamp) =
      DML.update(
        T,
        T.pid === v.pid && T.cid === v.cid,
        DML.set(
          T.cid.setTo(v.cid),
          T.name.setTo(v.name),
          T.street.setTo(v.street),
          T.zip.setTo(v.zip),
          T.city.setTo(v.city),
          T.country.setTo(v.country),
          T.concerning.setTo(v.concerning),
          T.notes.setTo(v.notes),
          T.oid.setTo(v.oid),
          T.updated.setTo(now)
        )
      )
    for {
      now <- Timestamp.current[ConnectionIO]
      n   <- sql(now)
    } yield n
  }

  def existsByName(coll: Ident, pname: String): ConnectionIO[Boolean] =
    run(select(count(T.pid)), from(T), T.cid === coll && T.name === pname)
      .query[Int]
      .unique
      .map(_ > 0)

  def findById(id: Ident): ConnectionIO[Option[RPerson]] = {
    val sql = run(select(T.all), from(T), T.cid === id)
    sql.query[RPerson].option
  }

  def find(coll: Ident, personName: String): ConnectionIO[Option[RPerson]] = {
    val sql = run(select(T.all), from(T), T.cid === coll && T.name === personName)
    sql.query[RPerson].option
  }

  def findLike(
      coll: Ident,
      personName: String,
      concerningOnly: Boolean
  ): ConnectionIO[Vector[IdRef]] =
    run(
      select(T.pid, T.name),
      from(T),
      where(T.cid === coll, T.concerning === concerningOnly, T.name.like(personName))
    ).query[IdRef].to[Vector]

  def findLike(
      coll: Ident,
      contactKind: ContactKind,
      value: String,
      concerningOnly: Boolean
  ): ConnectionIO[Vector[IdRef]] = {
    val p = RPerson.as("p")
    val c = RContact.as("c")

    runDistinct(
      select(p.pid, p.name),
      from(p).innerJoin(c, p.pid === c.personId),
      where(
        p.cid === coll,
        c.kind === contactKind,
        p.concerning === concerningOnly,
        c.value.like(value)
      )
    ).query[IdRef].to[Vector]
  }

  def findAll(
      coll: Ident,
      order: Table => Column[_]
  ): Stream[ConnectionIO, RPerson] = {
    val sql = Select(select(T.all), from(T), T.cid === coll).orderBy(order(T))
    sql.build.query[RPerson].stream
  }

  def findAllRef(
      coll: Ident,
      nameQ: Option[String],
      order: Table => Column[_]
  ): ConnectionIO[Vector[IdRef]] = {

    val nameFilter = nameQ.map(s => T.name.like(s"%${s.toLowerCase}%"))

    val sql = Select(select(T.pid, T.name), from(T), T.cid === coll &&? nameFilter)
      .orderBy(order(T))
    sql.build.query[IdRef].to[Vector]
  }

  def delete(personId: Ident, coll: Ident): ConnectionIO[Int] =
    DML.delete(T, T.pid === personId && T.cid === coll)

  def findOrganization(ids: Set[Ident]): ConnectionIO[Vector[PersonRef]] =
    NonEmptyList.fromList(ids.toList) match {
      case Some(nel) =>
        run(select(T.pid, T.name, T.oid), from(T), T.pid.in(nel))
          .query[PersonRef]
          .to[Vector]
      case None =>
        Sync[ConnectionIO].pure(Vector.empty)
    }

  def removeOrg(orgId: Ident): ConnectionIO[Int] =
    DML.update(T, T.oid === orgId, DML.set(T.oid.setTo(None)))
}
