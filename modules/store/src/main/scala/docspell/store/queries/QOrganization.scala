package docspell.store.queries

import cats.implicits._
import fs2._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records._
import docspell.store.{AddResult, Store}

import doobie._
import doobie.implicits._

object QOrganization {

  def findOrgAndContact(
      coll: Ident,
      query: Option[String],
      order: ROrganization.Table => Column[_]
  ): Stream[ConnectionIO, (ROrganization, Vector[RContact])] = {
    val org = ROrganization.as("o")
    val c   = RContact.as("c")

    val valFilter = query.map { q =>
      val v = s"%$q%"
      c.value.like(v) || org.name.like(v) || org.notes.like(v)
    }
    val sql = Select(
      select(org.all, c.all),
      from(org).leftJoin(c, c.orgId === org.oid),
      org.cid === coll &&? valFilter
    ).orderBy(order(org))

    sql.run
      .query[(ROrganization, Option[RContact])]
      .stream
      .groupAdjacentBy(_._1)
      .map({ case (ro, chunk) =>
        val cs = chunk.toVector.flatMap(_._2)
        (ro, cs)
      })
  }

  def getOrgAndContact(
      coll: Ident,
      orgId: Ident
  ): ConnectionIO[Option[(ROrganization, Vector[RContact])]] = {
    val org = ROrganization.as("o")
    val c   = RContact.as("c")

    val sql = run(
      select(org.all, c.all),
      from(org).leftJoin(c, c.orgId === org.oid),
      org.cid === coll && org.oid === orgId
    )

    sql
      .query[(ROrganization, Option[RContact])]
      .stream
      .groupAdjacentBy(_._1)
      .map({ case (ro, chunk) =>
        val cs = chunk.toVector.flatMap(_._2)
        (ro, cs)
      })
      .compile
      .last
  }

  def findPersonAndContact(
      coll: Ident,
      query: Option[String],
      order: RPerson.Table => Column[_]
  ): Stream[ConnectionIO, (RPerson, Option[ROrganization], Vector[RContact])] = {
    val pers = RPerson.as("p")
    val org  = ROrganization.as("o")
    val c    = RContact.as("c")
    val valFilter = query
      .map(s => s"%$s%")
      .map(v => c.value.like(v) || pers.name.like(v) || pers.notes.like(v))
    val sql = Select(
      select(pers.all, org.all, c.all),
      from(pers)
        .leftJoin(org, org.oid === pers.oid)
        .leftJoin(c, c.personId === pers.pid),
      pers.cid === coll &&? valFilter
    ).orderBy(order(pers))

    sql.run
      .query[(RPerson, Option[ROrganization], Option[RContact])]
      .stream
      .groupAdjacentBy(_._1)
      .map({ case (rp, chunk) =>
        val cs = chunk.toVector.flatMap(_._3)
        val ro = chunk.map(_._2).head.flatten
        (rp, ro, cs)
      })
  }

  def getPersonAndContact(
      coll: Ident,
      persId: Ident
  ): ConnectionIO[Option[(RPerson, Option[ROrganization], Vector[RContact])]] = {
    val pers = RPerson.as("p")
    val org  = ROrganization.as("o")
    val c    = RContact.as("c")
    val sql =
      run(
        select(pers.all, org.all, c.all),
        from(pers)
          .leftJoin(org, pers.oid === org.oid)
          .leftJoin(c, c.personId === pers.pid),
        pers.cid === coll && pers.pid === persId
      )

    sql
      .query[(RPerson, Option[ROrganization], Option[RContact])]
      .stream
      .groupAdjacentBy(_._1)
      .map({ case (rp, chunk) =>
        val cs = chunk.toVector.flatMap(_._3)
        val ro = chunk.map(_._2).head.flatten
        (rp, ro, cs)
      })
      .compile
      .last
  }

  def findPersonByContact(
      coll: Ident,
      value: String,
      ck: Option[ContactKind],
      concerning: Option[Boolean]
  ): Stream[ConnectionIO, RPerson] = {
    val p = RPerson.as("p")
    val c = RContact.as("c")
    runDistinct(
      select(p.all),
      from(p).innerJoin(c, c.personId === p.pid),
      c.value.like(s"%${value.toLowerCase}%") && p.cid === coll &&?
        concerning.map(c => p.concerning === c) &&?
        ck.map(k => c.kind === k)
    ).query[RPerson].stream
  }

  def addOrg[F[_]](
      org: ROrganization,
      contacts: Seq[RContact],
      cid: Ident
  ): Store[F] => F[AddResult] = {
    val insert = for {
      n  <- ROrganization.insert(org)
      cs <- contacts.toList.traverse(RContact.insert)
    } yield n + cs.sum

    val exists = ROrganization.existsByName(cid, org.name)

    store => store.add(insert, exists)
  }

  def addPerson[F[_]](
      person: RPerson,
      contacts: Seq[RContact],
      cid: Ident
  ): Store[F] => F[AddResult] = {
    val insert = for {
      n  <- RPerson.insert(person)
      cs <- contacts.toList.traverse(RContact.insert)
    } yield n + cs.sum

    val exists = RPerson.existsByName(cid, person.name)

    store => store.add(insert, exists)
  }

  def updateOrg[F[_]](
      org: ROrganization,
      contacts: Seq[RContact],
      cid: Ident
  ): Store[F] => F[AddResult] = {
    val insert = for {
      n  <- ROrganization.update(org)
      d  <- RContact.deleteOrg(org.oid)
      cs <- contacts.toList.traverse(RContact.insert)
    } yield n + cs.sum + d

    val exists = ROrganization.existsByName(cid, org.name)

    store => store.add(insert, exists)
  }

  def updatePerson[F[_]](
      person: RPerson,
      contacts: Seq[RContact],
      cid: Ident
  ): Store[F] => F[AddResult] = {
    val insert = for {
      n  <- RPerson.update(person)
      d  <- RContact.deletePerson(person.pid)
      cs <- contacts.toList.traverse(RContact.insert)
    } yield n + cs.sum + d

    val exists = RPerson.existsByName(cid, person.name)

    store => store.add(insert, exists)
  }

  def deleteOrg(orgId: Ident, collective: Ident): ConnectionIO[Int] =
    for {
      n0 <- RItem.removeCorrOrg(collective, orgId)
      n1 <- RContact.deleteOrg(orgId)
      n2 <- ROrganization.delete(orgId, collective)
    } yield n0 + n1 + n2

  def deletePerson(personId: Ident, collective: Ident): ConnectionIO[Int] =
    for {
      n0 <- RItem.removeCorrPerson(collective, personId)
      n1 <- RItem.removeConcPerson(collective, personId)
      n2 <- RContact.deletePerson(personId)
      n3 <- RPerson.delete(personId, collective)
    } yield n0 + n1 + n2 + n3
}
