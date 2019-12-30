package docspell.store.records

import doobie._, doobie.implicits._
import docspell.common._
import docspell.store.impl._
import docspell.store.impl.Implicits._

case class RContact(
    contactId: Ident,
    value: String,
    kind: ContactKind,
    personId: Option[Ident],
    orgId: Option[Ident],
    created: Timestamp
) {}

object RContact {

  val table = fr"contact"

  object Columns {
    val contactId = Column("contactid")
    val value     = Column("value")
    val kind      = Column("kind")
    val personId  = Column("pid")
    val orgId     = Column("oid")
    val created   = Column("created")
    val all       = List(contactId, value, kind, personId, orgId, created)
  }

  import Columns._

  def insert(v: RContact): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      all,
      fr"${v.contactId},${v.value},${v.kind},${v.personId},${v.orgId},${v.created}"
    )
    sql.update.run
  }

  def update(v: RContact): ConnectionIO[Int] = {
    val sql = updateRow(
      table,
      contactId.is(v.contactId),
      commas(
        value.setTo(v.value),
        kind.setTo(v.kind),
        personId.setTo(v.personId),
        orgId.setTo(v.orgId)
      )
    )
    sql.update.run
  }

  def delete(v: RContact): ConnectionIO[Int] =
    deleteFrom(table, contactId.is(v.contactId)).update.run

  def deleteOrg(oid: Ident): ConnectionIO[Int] =
    deleteFrom(table, orgId.is(oid)).update.run

  def deletePerson(pid: Ident): ConnectionIO[Int] =
    deleteFrom(table, personId.is(pid)).update.run

  def findById(id: Ident): ConnectionIO[Option[RContact]] = {
    val sql = selectSimple(all, table, contactId.is(id))
    sql.query[RContact].option
  }

  def findAllPerson(pid: Ident): ConnectionIO[Vector[RContact]] = {
    val sql = selectSimple(all, table, personId.is(pid))
    sql.query[RContact].to[Vector]
  }

  def findAllOrg(oid: Ident): ConnectionIO[Vector[RContact]] = {
    val sql = selectSimple(all, table, orgId.is(oid))
    sql.query[RContact].to[Vector]
  }
}
