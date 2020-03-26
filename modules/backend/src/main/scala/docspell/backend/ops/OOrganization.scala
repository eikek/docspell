package docspell.backend.ops

import cats.implicits._
import cats.effect.{Effect, Resource}
import docspell.common._
import docspell.store._
import docspell.store.records._
import OOrganization._
import docspell.store.queries.QOrganization

trait OOrganization[F[_]] {
  def findAllOrg(account: AccountId, query: Option[String]): F[Vector[OrgAndContacts]]

  def findAllOrgRefs(account: AccountId, nameQuery: Option[String]): F[Vector[IdRef]]

  def addOrg(s: OrgAndContacts): F[AddResult]

  def updateOrg(s: OrgAndContacts): F[AddResult]

  def findAllPerson(
      account: AccountId,
      query: Option[String]
  ): F[Vector[PersonAndContacts]]

  def findAllPersonRefs(account: AccountId, nameQuery: Option[String]): F[Vector[IdRef]]

  def addPerson(s: PersonAndContacts): F[AddResult]

  def updatePerson(s: PersonAndContacts): F[AddResult]

  def deleteOrg(orgId: Ident, collective: Ident): F[AddResult]

  def deletePerson(personId: Ident, collective: Ident): F[AddResult]
}

object OOrganization {

  case class OrgAndContacts(org: ROrganization, contacts: Seq[RContact])

  case class PersonAndContacts(person: RPerson, contacts: Seq[RContact])

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OOrganization[F]] =
    Resource.pure[F, OOrganization[F]](new OOrganization[F] {

      def findAllOrg(
          account: AccountId,
          query: Option[String]
      ): F[Vector[OrgAndContacts]] =
        store
          .transact(QOrganization.findOrgAndContact(account.collective, query, _.name))
          .map({ case (org, cont) => OrgAndContacts(org, cont) })
          .compile
          .toVector

      def findAllOrgRefs(
          account: AccountId,
          nameQuery: Option[String]
      ): F[Vector[IdRef]] =
        store.transact(ROrganization.findAllRef(account.collective, nameQuery, _.name))

      def addOrg(s: OrgAndContacts): F[AddResult] =
        QOrganization.addOrg(s.org, s.contacts, s.org.cid)(store)

      def updateOrg(s: OrgAndContacts): F[AddResult] =
        QOrganization.updateOrg(s.org, s.contacts, s.org.cid)(store)

      def findAllPerson(
          account: AccountId,
          query: Option[String]
      ): F[Vector[PersonAndContacts]] =
        store
          .transact(QOrganization.findPersonAndContact(account.collective, query, _.name))
          .map({ case (person, cont) => PersonAndContacts(person, cont) })
          .compile
          .toVector

      def findAllPersonRefs(
          account: AccountId,
          nameQuery: Option[String]
      ): F[Vector[IdRef]] =
        store.transact(RPerson.findAllRef(account.collective, nameQuery, _.name))

      def addPerson(s: PersonAndContacts): F[AddResult] =
        QOrganization.addPerson(s.person, s.contacts, s.person.cid)(store)

      def updatePerson(s: PersonAndContacts): F[AddResult] =
        QOrganization.updatePerson(s.person, s.contacts, s.person.cid)(store)

      def deleteOrg(orgId: Ident, collective: Ident): F[AddResult] =
        store
          .transact(QOrganization.deleteOrg(orgId, collective))
          .attempt
          .map(AddResult.fromUpdate)

      def deletePerson(personId: Ident, collective: Ident): F[AddResult] =
        store
          .transact(QOrganization.deletePerson(personId, collective))
          .attempt
          .map(AddResult.fromUpdate)

    })
}
