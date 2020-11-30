package docspell.store.records

import cats.Eq
import fs2.Stream

import docspell.common.{IdRef, _}
import docspell.store.impl.Implicits._
import docspell.store.impl._

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

  val table = fr"person"

  object Columns {
    val pid        = Column("pid")
    val cid        = Column("cid")
    val name       = Column("name")
    val street     = Column("street")
    val zip        = Column("zip")
    val city       = Column("city")
    val country    = Column("country")
    val notes      = Column("notes")
    val concerning = Column("concerning")
    val created    = Column("created")
    val updated    = Column("updated")
    val oid        = Column("oid")
    val all = List(
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

  import Columns._

  def insert(v: RPerson): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      all,
      fr"${v.pid},${v.cid},${v.name},${v.street},${v.zip},${v.city},${v.country},${v.notes},${v.concerning},${v.created},${v.updated},${v.oid}"
    )
    sql.update.run
  }

  def update(v: RPerson): ConnectionIO[Int] = {
    def sql(now: Timestamp) =
      updateRow(
        table,
        and(pid.is(v.pid), cid.is(v.cid)),
        commas(
          cid.setTo(v.cid),
          name.setTo(v.name),
          street.setTo(v.street),
          zip.setTo(v.zip),
          city.setTo(v.city),
          country.setTo(v.country),
          concerning.setTo(v.concerning),
          notes.setTo(v.notes),
          oid.setTo(v.oid),
          updated.setTo(now)
        )
      )
    for {
      now <- Timestamp.current[ConnectionIO]
      n   <- sql(now).update.run
    } yield n
  }

  def existsByName(coll: Ident, pname: String): ConnectionIO[Boolean] =
    selectCount(pid, table, and(cid.is(coll), name.is(pname)))
      .query[Int]
      .unique
      .map(_ > 0)

  def findById(id: Ident): ConnectionIO[Option[RPerson]] = {
    val sql = selectSimple(all, table, cid.is(id))
    sql.query[RPerson].option
  }

  def find(coll: Ident, personName: String): ConnectionIO[Option[RPerson]] = {
    val sql = selectSimple(all, table, and(cid.is(coll), name.is(personName)))
    sql.query[RPerson].option
  }

  def findLike(
      coll: Ident,
      personName: String,
      concerningOnly: Boolean
  ): ConnectionIO[Vector[IdRef]] =
    selectSimple(
      List(pid, name),
      table,
      and(cid.is(coll), concerning.is(concerningOnly), name.lowerLike(personName))
    ).query[IdRef].to[Vector]

  def findLike(
      coll: Ident,
      contactKind: ContactKind,
      value: String,
      concerningOnly: Boolean
  ): ConnectionIO[Vector[IdRef]] = {
    val CC = RContact.Columns
    val q = fr"SELECT DISTINCT" ++ commas(pid.prefix("p").f, name.prefix("p").f) ++
      fr"FROM" ++ table ++ fr"p" ++
      fr"INNER JOIN" ++ RContact.table ++ fr"c ON" ++ CC.personId
        .prefix("c")
        .is(pid.prefix("p")) ++
      fr"WHERE" ++ and(
        cid.prefix("p").is(coll),
        CC.kind.prefix("c").is(contactKind),
        concerning.prefix("p").is(concerningOnly),
        CC.value.prefix("c").lowerLike(value)
      )

    q.query[IdRef].to[Vector]
  }

  def findAll(
      coll: Ident,
      order: Columns.type => Column
  ): Stream[ConnectionIO, RPerson] = {
    val sql = selectSimple(all, table, cid.is(coll)) ++ orderBy(order(Columns).f)
    sql.query[RPerson].stream
  }

  def findAllRef(
      coll: Ident,
      nameQ: Option[String],
      order: Columns.type => Column
  ): ConnectionIO[Vector[IdRef]] = {
    val q = Seq(cid.is(coll)) ++ (nameQ match {
      case Some(str) => Seq(name.lowerLike(s"%${str.toLowerCase}%"))
      case None      => Seq.empty
    })
    val sql = selectSimple(List(pid, name), table, and(q)) ++ orderBy(order(Columns).f)
    sql.query[IdRef].to[Vector]
  }

  def delete(personId: Ident, coll: Ident): ConnectionIO[Int] =
    deleteFrom(table, and(pid.is(personId), cid.is(coll))).update.run
}
