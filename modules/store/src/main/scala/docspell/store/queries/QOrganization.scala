package docspell.store.queries

import fs2._
import cats.implicits._
import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.{AddResult, Store}
import docspell.store.impl.Column
import docspell.store.impl.Implicits._
import docspell.store.records.ROrganization.{Columns => OC}
import docspell.store.records.RPerson.{Columns => PC}
import docspell.store.records._

object QOrganization {

  def findOrgAndContact(
      coll: Ident,
      query: Option[String],
      order: OC.type => Column
  ): Stream[ConnectionIO, (ROrganization, Vector[RContact])] = {
    val oColl  = ROrganization.Columns.cid.prefix("o")
    val oName  = ROrganization.Columns.name.prefix("o")
    val oNotes = ROrganization.Columns.notes.prefix("o")
    val oId    = ROrganization.Columns.oid.prefix("o")
    val cOrg   = RContact.Columns.orgId.prefix("c")
    val cVal   = RContact.Columns.value.prefix("c")

    val cols = ROrganization.Columns.all.map(_.prefix("o")) ++ RContact.Columns.all
      .map(_.prefix("c"))
    val from = ROrganization.table ++ fr"o LEFT JOIN" ++
      RContact.table ++ fr"c ON" ++ cOrg.is(oId)

    val q = Seq(oColl.is(coll)) ++ (query match {
      case Some(str) =>
        val v = s"%$str%"
        Seq(or(cVal.lowerLike(v), oName.lowerLike(v), oNotes.lowerLike(v)))
      case None =>
        Seq.empty
    })

    (selectSimple(cols, from, and(q)) ++ orderBy(order(OC).f))
      .query[(ROrganization, Option[RContact])]
      .stream
      .groupAdjacentBy(_._1)
      .map({
        case (ro, chunk) =>
          val cs = chunk.toVector.flatMap(_._2)
          (ro, cs)
      })
  }

  def findPersonAndContact(
      coll: Ident,
      query: Option[String],
      order: PC.type => Column
  ): Stream[ConnectionIO, (RPerson, Vector[RContact])] = {
    val pColl  = PC.cid.prefix("p")
    val pName  = RPerson.Columns.name.prefix("p")
    val pNotes = RPerson.Columns.notes.prefix("p")
    val pId    = RPerson.Columns.pid.prefix("p")
    val cPers  = RContact.Columns.personId.prefix("c")
    val cVal   = RContact.Columns.value.prefix("c")

    val cols = RPerson.Columns.all.map(_.prefix("p")) ++ RContact.Columns.all
      .map(_.prefix("c"))
    val from = RPerson.table ++ fr"p LEFT JOIN" ++
      RContact.table ++ fr"c ON" ++ cPers.is(pId)

    val q = Seq(pColl.is(coll)) ++ (query match {
      case Some(str) =>
        val v = s"%${str.toLowerCase}%"
        Seq(or(cVal.lowerLike(v), pName.lowerLike(v), pNotes.lowerLike(v)))
      case None =>
        Seq.empty
    })

    (selectSimple(cols, from, and(q)) ++ orderBy(order(PC).f))
      .query[(RPerson, Option[RContact])]
      .stream
      .groupAdjacentBy(_._1)
      .map({
        case (ro, chunk) =>
          val cs = chunk.toVector.flatMap(_._2)
          (ro, cs)
      })
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
