package docspell.backend.ops

import cats.effect._

import docspell.common._
import docspell.store.{AddResult, Store}
import docspell.store.records.{RSpace, RUser}
import docspell.store.queries.QSpace

trait OSpace[F[_]] {

  def findAll(
      account: AccountId,
      ownerLogin: Option[Ident],
      nameQuery: Option[String]
  ): F[Vector[OSpace.SpaceItem]]

  def findById(id: Ident, account: AccountId): F[Option[OSpace.SpaceDetail]]

  /** Adds a new space. If `login` is non-empty, the `space.user`
    * property is ignored and the user-id is determined by the given
    * login name.
    */
  def add(space: RSpace, login: Option[Ident]): F[AddResult]

  def changeName(
      space: Ident,
      account: AccountId,
      name: String
  ): F[OSpace.SpaceChangeResult]

  def addMember(
      space: Ident,
      account: AccountId,
      member: Ident
  ): F[OSpace.SpaceChangeResult]

  def removeMember(
      space: Ident,
      account: AccountId,
      member: Ident
  ): F[OSpace.SpaceChangeResult]

  def delete(id: Ident, account: AccountId): F[OSpace.SpaceChangeResult]
}

object OSpace {

  type SpaceChangeResult = QSpace.SpaceChangeResult
  val SpaceChangeResult = QSpace.SpaceChangeResult

  type SpaceItem = QSpace.SpaceItem
  val SpaceItem = QSpace.SpaceItem

  type SpaceDetail = QSpace.SpaceDetail
  val SpaceDetail = QSpace.SpaceDetail

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OSpace[F]] =
    Resource.pure[F, OSpace[F]](new OSpace[F] {
      def findAll(
          account: AccountId,
          ownerLogin: Option[Ident],
          nameQuery: Option[String]
      ): F[Vector[SpaceItem]] =
        store.transact(QSpace.findAll(account, None, ownerLogin, nameQuery))

      def findById(id: Ident, account: AccountId): F[Option[SpaceDetail]] =
        store.transact(QSpace.findById(id, account))

      def add(space: RSpace, login: Option[Ident]): F[AddResult] = {
        val insert = login match {
          case Some(n) =>
            for {
              user <- RUser.findByAccount(AccountId(space.collectiveId, n))
              s = user.map(u => space.copy(owner = u.uid)).getOrElse(space)
              n <- RSpace.insert(s)
            } yield n

          case None =>
            RSpace.insert(space)
        }
        val exists = RSpace.existsByName(space.collectiveId, space.name)
        store.add(insert, exists)
      }

      def changeName(
          space: Ident,
          account: AccountId,
          name: String
      ): F[SpaceChangeResult] =
        store.transact(QSpace.changeName(space, account, name))

      def addMember(
          space: Ident,
          account: AccountId,
          member: Ident
      ): F[SpaceChangeResult] =
        store.transact(QSpace.addMember(space, account, member))

      def removeMember(
          space: Ident,
          account: AccountId,
          member: Ident
      ): F[SpaceChangeResult] =
        store.transact(QSpace.removeMember(space, account, member))

      def delete(id: Ident, account: AccountId): F[SpaceChangeResult] =
        store.transact(QSpace.delete(id, account))
    })
}
