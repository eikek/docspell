package docspell.store.queries

import fs2._
import cats.implicits._
import doobie._
import docspell.common._
import docspell.store.{AddResult, Store}
import docspell.store.impl.Column
import docspell.store.records.ROrganization.{Columns => OC}
import docspell.store.records.RPerson.{Columns => PC}
import docspell.store.records._

object QOrganization {

  def findOrgAndContact(
      coll: Ident,
      order: OC.type => Column
  ): Stream[ConnectionIO, (ROrganization, Vector[RContact])] =
    ROrganization
      .findAll(coll, order)
      .evalMap(ro => RContact.findAllOrg(ro.oid).map(cs => (ro, cs)))
  def findPersonAndContact(
      coll: Ident,
      order: PC.type => Column
  ): Stream[ConnectionIO, (RPerson, Vector[RContact])] =
    RPerson.findAll(coll, order).evalMap(ro => RContact.findAllPerson(ro.pid).map(cs => (ro, cs)))

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
