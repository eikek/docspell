package docspell.backend.ops

import cats.effect._

import docspell.common._
import docspell.store.{AddResult, Store}
import docspell.store.records.RSpace

trait OSpace[F[_]] {

  def findAll(account: AccountId, nameQuery: Option[String]): F[Vector[OSpace.SpaceItem]]

  def findById(id: Ident, collective: Ident): F[Option[OSpace.SpaceDetail]]

  def delete(id: Ident, collective: Ident): F[Int]

  def add(space: RSpace): F[AddResult]

  def changeName(space: Ident, account: AccountId, name: String): F[AddResult]

  def addMember(
      space: Ident,
      account: AccountId,
      member: Ident
  ): F[OSpace.MemberChangeResult]
  def removeMember(
      space: Ident,
      account: AccountId,
      member: Ident
  ): F[OSpace.MemberChangeResult]
}

object OSpace {

  sealed trait MemberChangeResult
  object MemberChangeResult {
    case object Success   extends MemberChangeResult
    case object NotFound  extends MemberChangeResult
    case object Forbidden extends MemberChangeResult
  }

  final case class SpaceItem(
      id: Ident,
      name: String,
      owner: IdRef,
      created: Timestamp,
      members: Int
  )

  final case class SpaceDetail(
      id: Ident,
      name: String,
      owner: IdRef,
      created: Timestamp,
      members: List[IdRef]
  )

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OSpace[F]] =
    Resource.pure[F, OSpace[F]](new OSpace[F] {
      println(s"$store")
      def findAll(
          account: AccountId,
          nameQuery: Option[String]
      ): F[Vector[OSpace.SpaceItem]] = ???

      def findById(id: Ident, collective: Ident): F[Option[OSpace.SpaceDetail]]    = ???
      def add(space: RSpace): F[AddResult]                                         = ???
      def changeName(space: Ident, account: AccountId, name: String): F[AddResult] = ???
      def delete(id: Ident, collective: Ident): F[Int]                             = ???
      def addMember(
          space: Ident,
          account: AccountId,
          member: Ident
      ): F[MemberChangeResult] =
        ???
      def removeMember(
          space: Ident,
          account: AccountId,
          member: Ident
      ): F[MemberChangeResult] =
        ???

    })
}
