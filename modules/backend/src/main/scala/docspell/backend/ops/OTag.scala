/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.NonEmptyList
import cats.effect.{Async, Resource}
import cats.implicits._

import docspell.common.{AccountId, Ident}
import docspell.store.records.RTagSource
import docspell.store.records.{RTag, RTagItem}
import docspell.store.{AddResult, Store}

trait OTag[F[_]] {

  def findAll(
      account: AccountId,
      query: Option[String],
      order: OTag.TagOrder
  ): F[Vector[RTag]]

  def add(s: RTag): F[AddResult]

  def update(s: RTag): F[AddResult]

  def delete(id: Ident, collective: Ident): F[AddResult]

  /** Load all tags given their ids. Ids that are not available are ignored. */
  def loadAll(ids: List[Ident]): F[Vector[RTag]]
}

object OTag {
  import docspell.store.qb.DSL._

  sealed trait TagOrder
  object TagOrder {
    final case object NameAsc extends TagOrder
    final case object NameDesc extends TagOrder
    final case object CategoryAsc extends TagOrder
    final case object CategoryDesc extends TagOrder

    def parse(str: String): Either[String, TagOrder] =
      str.toLowerCase match {
        case "name"      => Right(NameAsc)
        case "-name"     => Right(NameDesc)
        case "category"  => Right(CategoryAsc)
        case "-category" => Right(CategoryDesc)
        case _           => Left(s"Unknown sort property for tags: $str")
      }

    def parseOrDefault(str: String): TagOrder =
      parse(str).toOption.getOrElse(NameAsc)

    private[ops] def apply(order: TagOrder)(table: RTag.Table) = order match {
      case NameAsc      => NonEmptyList.of(table.name.asc)
      case CategoryAsc  => NonEmptyList.of(table.category.asc, table.name.asc)
      case NameDesc     => NonEmptyList.of(table.name.desc)
      case CategoryDesc => NonEmptyList.of(table.category.desc, table.name.desc)
    }
  }

  def apply[F[_]: Async](store: Store[F]): Resource[F, OTag[F]] =
    Resource.pure[F, OTag[F]](new OTag[F] {
      def findAll(
          account: AccountId,
          query: Option[String],
          order: TagOrder
      ): F[Vector[RTag]] =
        store.transact(RTag.findAll(account.collective, query, TagOrder(order)))

      def add(t: RTag): F[AddResult] = {
        def insert = RTag.insert(t)
        def exists = RTag.existsByName(t)

        val msg = s"A tag '${t.name}' already exists"
        store.add(insert, exists).map(_.fold(identity, _.withMsg(msg), identity))
      }

      def update(t: RTag): F[AddResult] = {
        def insert = RTag.update(t)
        def exists = RTag.existsByName(t)

        val msg = s"A tag '${t.name}' already exists"
        store.add(insert, exists).map(_.fold(identity, _.withMsg(msg), identity))
      }

      def delete(id: Ident, collective: Ident): F[AddResult] = {
        val io = for {
          optTag <- RTag.findByIdAndCollective(id, collective)
          n0 <- optTag.traverse(t => RTagItem.deleteTag(t.tagId))
          n1 <- optTag.traverse(t => RTagSource.deleteTag(t.tagId))
          n2 <- optTag.traverse(t => RTag.delete(t.tagId, collective))
        } yield (n0 |+| n1 |+| n2).getOrElse(0)
        store.transact(io).attempt.map(AddResult.fromUpdate)
      }

      def loadAll(ids: List[Ident]): F[Vector[RTag]] =
        if (ids.isEmpty) Vector.empty.pure[F]
        else store.transact(RTag.findAllById(ids))
    })
}
