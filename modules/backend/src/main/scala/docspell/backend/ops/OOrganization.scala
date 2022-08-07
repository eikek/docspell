/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.NonEmptyList
import cats.effect.{Async, Resource}
import cats.implicits._

import docspell.backend.ops.OOrganization._
import docspell.common._
import docspell.store._
import docspell.store.queries.QOrganization
import docspell.store.records._

trait OOrganization[F[_]] {
  def findAllOrg(
      collectiveId: CollectiveId,
      query: Option[String],
      order: OrganizationOrder
  ): F[Vector[OrgAndContacts]]

  def findOrg(collectiveId: CollectiveId, orgId: Ident): F[Option[OrgAndContacts]]

  def findAllOrgRefs(
      collectiveId: CollectiveId,
      nameQuery: Option[String],
      order: OrganizationOrder
  ): F[Vector[IdRef]]

  def addOrg(s: OrgAndContacts): F[AddResult]

  def updateOrg(s: OrgAndContacts): F[AddResult]

  def findAllPerson(
      collectiveId: CollectiveId,
      query: Option[String],
      order: PersonOrder
  ): F[Vector[PersonAndContacts]]

  def findPerson(collectiveId: CollectiveId, persId: Ident): F[Option[PersonAndContacts]]

  def findAllPersonRefs(
      collectiveId: CollectiveId,
      nameQuery: Option[String],
      order: PersonOrder
  ): F[Vector[IdRef]]

  /** Add a new person with their contacts. The additional organization is ignored. */
  def addPerson(s: PersonAndContacts): F[AddResult]

  /** Update a person with their contacts. The additional organization is ignored. */
  def updatePerson(s: PersonAndContacts): F[AddResult]

  def deleteOrg(orgId: Ident, collective: CollectiveId): F[AddResult]

  def deletePerson(personId: Ident, collective: CollectiveId): F[AddResult]
}

object OOrganization {
  import docspell.store.qb.DSL._

  case class OrgAndContacts(org: ROrganization, contacts: Seq[RContact])

  case class PersonAndContacts(
      person: RPerson,
      org: Option[ROrganization],
      contacts: Seq[RContact]
  )

  sealed trait OrganizationOrder
  object OrganizationOrder {
    final case object NameAsc extends OrganizationOrder
    final case object NameDesc extends OrganizationOrder

    def parse(str: String): Either[String, OrganizationOrder] =
      str.toLowerCase match {
        case "name"  => Right(NameAsc)
        case "-name" => Right(NameDesc)
        case _       => Left(s"Unknown sort property for organization: $str")
      }

    def parseOrDefault(str: String): OrganizationOrder =
      parse(str).toOption.getOrElse(NameAsc)

    private[ops] def apply(order: OrganizationOrder)(table: ROrganization.Table) =
      order match {
        case NameAsc  => NonEmptyList.of(table.name.asc)
        case NameDesc => NonEmptyList.of(table.name.desc)
      }
  }

  sealed trait PersonOrder
  object PersonOrder {
    final case object NameAsc extends PersonOrder
    final case object NameDesc extends PersonOrder
    final case object OrgAsc extends PersonOrder
    final case object OrgDesc extends PersonOrder

    def parse(str: String): Either[String, PersonOrder] =
      str.toLowerCase match {
        case "name"  => Right(NameAsc)
        case "-name" => Right(NameDesc)
        case "org"   => Right(OrgAsc)
        case "-org"  => Right(OrgDesc)
        case _       => Left(s"Unknown sort property for person: $str")
      }

    def parseOrDefault(str: String): PersonOrder =
      parse(str).toOption.getOrElse(NameAsc)

    private[ops] def apply(
        order: PersonOrder
    )(person: RPerson.Table, org: ROrganization.Table) =
      order match {
        case NameAsc  => NonEmptyList.of(person.name.asc)
        case NameDesc => NonEmptyList.of(person.name.desc)
        case OrgAsc   => NonEmptyList.of(org.name.asc)
        case OrgDesc  => NonEmptyList.of(org.name.desc)
      }

    private[ops] def nameOnly(order: PersonOrder)(person: RPerson.Table) =
      order match {
        case NameAsc  => NonEmptyList.of(person.name.asc)
        case NameDesc => NonEmptyList.of(person.name.desc)
        case OrgAsc   => NonEmptyList.of(person.name.asc)
        case OrgDesc  => NonEmptyList.of(person.name.asc)
      }
  }

  def apply[F[_]: Async](store: Store[F]): Resource[F, OOrganization[F]] =
    Resource.pure[F, OOrganization[F]](new OOrganization[F] {

      def findAllOrg(
          collectiveId: CollectiveId,
          query: Option[String],
          order: OrganizationOrder
      ): F[Vector[OrgAndContacts]] =
        store
          .transact(
            QOrganization
              .findOrgAndContact(collectiveId, query, OrganizationOrder(order))
          )
          .map { case (org, cont) => OrgAndContacts(org, cont) }
          .compile
          .toVector

      def findOrg(collectiveId: CollectiveId, orgId: Ident): F[Option[OrgAndContacts]] =
        store
          .transact(QOrganization.getOrgAndContact(collectiveId, orgId))
          .map(_.map { case (org, cont) => OrgAndContacts(org, cont) })

      def findAllOrgRefs(
          collectiveId: CollectiveId,
          nameQuery: Option[String],
          order: OrganizationOrder
      ): F[Vector[IdRef]] =
        store.transact(
          ROrganization.findAllRef(
            collectiveId,
            nameQuery,
            OrganizationOrder(order)
          )
        )

      def addOrg(s: OrgAndContacts): F[AddResult] =
        QOrganization.addOrg(s.org, s.contacts, s.org.cid)(store)

      def updateOrg(s: OrgAndContacts): F[AddResult] =
        QOrganization.updateOrg(s.org, s.contacts, s.org.cid)(store)

      def findAllPerson(
          collectiveId: CollectiveId,
          query: Option[String],
          order: PersonOrder
      ): F[Vector[PersonAndContacts]] =
        store
          .transact(
            QOrganization
              .findPersonAndContact(collectiveId, query, PersonOrder(order))
          )
          .map { case (person, org, cont) => PersonAndContacts(person, org, cont) }
          .compile
          .toVector

      def findPerson(
          collectiveId: CollectiveId,
          persId: Ident
      ): F[Option[PersonAndContacts]] =
        store
          .transact(QOrganization.getPersonAndContact(collectiveId, persId))
          .map(_.map { case (pers, org, cont) => PersonAndContacts(pers, org, cont) })

      def findAllPersonRefs(
          collectiveId: CollectiveId,
          nameQuery: Option[String],
          order: PersonOrder
      ): F[Vector[IdRef]] =
        store.transact(
          RPerson.findAllRef(collectiveId, nameQuery, PersonOrder.nameOnly(order))
        )

      def addPerson(s: PersonAndContacts): F[AddResult] =
        QOrganization.addPerson(s.person, s.contacts, s.person.cid)(store)

      def updatePerson(s: PersonAndContacts): F[AddResult] =
        QOrganization.updatePerson(s.person, s.contacts, s.person.cid)(store)

      def deleteOrg(orgId: Ident, collective: CollectiveId): F[AddResult] =
        store
          .transact(QOrganization.deleteOrg(orgId, collective))
          .attempt
          .map(AddResult.fromUpdate)

      def deletePerson(personId: Ident, collective: CollectiveId): F[AddResult] =
        store
          .transact(QOrganization.deletePerson(personId, collective))
          .attempt
          .map(AddResult.fromUpdate)

    })
}
