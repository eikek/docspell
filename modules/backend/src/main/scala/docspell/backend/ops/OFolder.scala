package docspell.backend.ops

import cats.effect._

import docspell.common._
import docspell.store.queries.QFolder
import docspell.store.records.{RFolder, RUser}
import docspell.store.{AddResult, Store}

trait OFolder[F[_]] {

  def findAll(
      account: AccountId,
      ownerLogin: Option[Ident],
      nameQuery: Option[String]
  ): F[Vector[OFolder.FolderItem]]

  def findById(id: Ident, account: AccountId): F[Option[OFolder.FolderDetail]]

  /** Adds a new folder. If `login` is non-empty, the `folder.user`
    * property is ignored and the user-id is determined by the given
    * login name.
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

  type FolderChangeResult = QFolder.FolderChangeResult
  val FolderChangeResult = QFolder.FolderChangeResult

  type FolderItem = QFolder.FolderItem
  val FolderItem = QFolder.FolderItem

  type FolderDetail = QFolder.FolderDetail
  val FolderDetail = QFolder.FolderDetail

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OFolder[F]] =
    Resource.pure[F, OFolder[F]](new OFolder[F] {
      def findAll(
          account: AccountId,
          ownerLogin: Option[Ident],
          nameQuery: Option[String]
      ): F[Vector[FolderItem]] =
        store.transact(QFolder.findAll(account, None, ownerLogin, nameQuery))

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
