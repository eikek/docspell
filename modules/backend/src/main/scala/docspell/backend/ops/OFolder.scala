/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.{NonEmptyList => Nel}
import cats.effect._

import docspell.common._
import docspell.store.queries.QFolder
import docspell.store.records.{RFolder, RUser}
import docspell.store.{AddResult, Store}

trait OFolder[F[_]] {

  def findAll(
      account: AccountId,
      ownerLogin: Option[Ident],
      query: Option[String],
      order: OFolder.FolderOrder
  ): F[Vector[OFolder.FolderItem]]

  def findById(id: Ident, account: AccountId): F[Option[OFolder.FolderDetail]]

  /** Adds a new folder. If `login` is non-empty, the `folder.user` property is ignored
    * and the user-id is determined by the given login name.
    */
  def add(folder: RFolder, login: Option[Ident]): F[AddResult]

  def changeName(
      folder: Ident,
      account: AccountId,
      name: String
  ): F[OFolder.FolderChangeResult]

  def addMember(
      folder: Ident,
      account: AccountId,
      member: Ident
  ): F[OFolder.FolderChangeResult]

  def removeMember(
      folder: Ident,
      account: AccountId,
      member: Ident
  ): F[OFolder.FolderChangeResult]

  def delete(id: Ident, account: AccountId): F[OFolder.FolderChangeResult]
}

object OFolder {
  import docspell.store.qb.DSL._

  type FolderChangeResult = QFolder.FolderChangeResult
  val FolderChangeResult = QFolder.FolderChangeResult

  type FolderItem = QFolder.FolderItem
  val FolderItem = QFolder.FolderItem

  type FolderDetail = QFolder.FolderDetail
  val FolderDetail = QFolder.FolderDetail

  sealed trait FolderOrder
  object FolderOrder {
    final case object NameAsc extends FolderOrder
    final case object NameDesc extends FolderOrder
    final case object OwnerAsc extends FolderOrder
    final case object OwnerDesc extends FolderOrder

    def parse(str: String): Either[String, FolderOrder] =
      str.toLowerCase match {
        case "name"   => Right(NameAsc)
        case "-name"  => Right(NameDesc)
        case "owner"  => Right(OwnerAsc)
        case "-owner" => Right(OwnerDesc)
        case _        => Left(s"Unknown sort property for folder: $str")
      }

    def parseOrDefault(str: String): FolderOrder =
      parse(str).toOption.getOrElse(NameAsc)

    private[ops] def apply(order: FolderOrder)(folder: RFolder.Table, user: RUser.Table) =
      order match {
        case NameAsc   => Nel.of(folder.name.asc)
        case NameDesc  => Nel.of(folder.name.desc)
        case OwnerAsc  => Nel.of(user.login.asc, folder.name.asc)
        case OwnerDesc => Nel.of(user.login.desc, folder.name.desc)
      }
  }

  def apply[F[_]](store: Store[F]): Resource[F, OFolder[F]] =
    Resource.pure[F, OFolder[F]](new OFolder[F] {
      def findAll(
          account: AccountId,
          ownerLogin: Option[Ident],
          query: Option[String],
          order: FolderOrder
      ): F[Vector[FolderItem]] =
        store.transact(
          QFolder.findAll(account, None, ownerLogin, query, FolderOrder(order))
        )

      def findById(id: Ident, account: AccountId): F[Option[FolderDetail]] =
        store.transact(QFolder.findById(id, account))

      def add(folder: RFolder, login: Option[Ident]): F[AddResult] = {
        val insert = login match {
          case Some(n) =>
            for {
              user <- RUser.findByAccount(AccountId(folder.collectiveId, n))
              s = user.map(u => folder.copy(owner = u.uid)).getOrElse(folder)
              n <- RFolder.insert(s)
            } yield n

          case None =>
            RFolder.insert(folder)
        }
        val exists = RFolder.existsByName(folder.collectiveId, folder.name)
        store.add(insert, exists)
      }

      def changeName(
          folder: Ident,
          account: AccountId,
          name: String
      ): F[FolderChangeResult] =
        store.transact(QFolder.changeName(folder, account, name))

      def addMember(
          folder: Ident,
          account: AccountId,
          member: Ident
      ): F[FolderChangeResult] =
        store.transact(QFolder.addMember(folder, account, member))

      def removeMember(
          folder: Ident,
          account: AccountId,
          member: Ident
      ): F[FolderChangeResult] =
        store.transact(QFolder.removeMember(folder, account, member))

      def delete(id: Ident, account: AccountId): F[FolderChangeResult] =
        store.transact(QFolder.delete(id, account))
    })
}
