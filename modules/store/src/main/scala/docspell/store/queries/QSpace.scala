package docspell.store.queries

import cats.data.OptionT
import cats.implicits._

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.records._

import doobie._
import doobie.implicits._

object QSpace {

  final case class SpaceItem(
      id: Ident,
      name: String,
      owner: IdRef,
      created: Timestamp
  ) {
    def withMembers(members: List[IdRef]): SpaceDetail =
      SpaceDetail(id, name, owner, created, members)
  }

  final case class SpaceDetail(
      id: Ident,
      name: String,
      owner: IdRef,
      created: Timestamp,
      members: List[IdRef]
  )

  sealed trait SpaceChangeResult
  object SpaceChangeResult {
    case object Success extends SpaceChangeResult
    def success: SpaceChangeResult = Success
    case object NotFound extends SpaceChangeResult
    def notFound: SpaceChangeResult = NotFound
    case object Forbidden extends SpaceChangeResult
    def forbidden: SpaceChangeResult = Forbidden
    case object Exists extends SpaceChangeResult
    def exists: SpaceChangeResult = Exists
  }

  def delete(id: Ident, account: AccountId): ConnectionIO[SpaceChangeResult] = {
    def tryDelete =
      for {
        _ <- RItem.removeSpace(id)
        _ <- RSpaceMember.deleteAll(id)
        _ <- RSpace.delete(id)
      } yield SpaceChangeResult.success

    (for {
      uid   <- OptionT(findUserId(account))
      space <- OptionT(RSpace.findById(id))
      res <- OptionT.liftF(
        if (space.owner == uid) tryDelete
        else SpaceChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(SpaceChangeResult.notFound)
  }

  def changeName(
      space: Ident,
      account: AccountId,
      name: String
  ): ConnectionIO[SpaceChangeResult] = {
    def tryUpdate(ns: RSpace): ConnectionIO[SpaceChangeResult] =
      for {
        n <- RSpace.update(ns)
        res =
          if (n == 0) SpaceChangeResult.notFound
          else SpaceChangeResult.Success
      } yield res

    (for {
      uid   <- OptionT(findUserId(account))
      space <- OptionT(RSpace.findById(space))
      res <- OptionT.liftF(
        if (space.owner == uid) tryUpdate(space.copy(name = name))
        else SpaceChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(SpaceChangeResult.notFound)
  }

  def removeMember(
      space: Ident,
      account: AccountId,
      member: Ident
  ): ConnectionIO[SpaceChangeResult] = {
    def tryRemove: ConnectionIO[SpaceChangeResult] =
      for {
        n <- RSpaceMember.delete(member, space)
        res =
          if (n == 0) SpaceChangeResult.notFound
          else SpaceChangeResult.Success
      } yield res

    (for {
      uid   <- OptionT(findUserId(account))
      space <- OptionT(RSpace.findById(space))
      res <- OptionT.liftF(
        if (space.owner == uid) tryRemove
        else SpaceChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(SpaceChangeResult.notFound)
  }

  def addMember(
      space: Ident,
      account: AccountId,
      member: Ident
  ): ConnectionIO[SpaceChangeResult] = {
    def tryAdd: ConnectionIO[SpaceChangeResult] =
      for {
        spm <- RSpaceMember.findByUserId(member, space)
        mem <- RSpaceMember.newMember[ConnectionIO](space, member)
        res <-
          if (spm.isDefined) SpaceChangeResult.exists.pure[ConnectionIO]
          else RSpaceMember.insert(mem).map(_ => SpaceChangeResult.Success)
      } yield res

    (for {
      uid   <- OptionT(findUserId(account))
      space <- OptionT(RSpace.findById(space))
      res <- OptionT.liftF(
        if (space.owner == uid) tryAdd
        else SpaceChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(SpaceChangeResult.notFound)
  }

  def findById(id: Ident, collective: Ident): ConnectionIO[Option[SpaceDetail]] = {
    val mUserId  = RSpaceMember.Columns.user.prefix("m")
    val mSpaceId = RSpaceMember.Columns.space.prefix("m")
    val uId      = RUser.Columns.uid.prefix("u")
    val uLogin   = RUser.Columns.login.prefix("u")
    val sColl    = RSpace.Columns.collective.prefix("s")
    val sId      = RSpace.Columns.id.prefix("s")

    val from = RSpaceMember.table ++ fr"m INNER JOIN" ++
      RUser.table ++ fr"u ON" ++ mUserId.is(uId) ++ fr"INNER JOIN" ++
      RSpace.table ++ fr"s ON" ++ mSpaceId.is(sId)

    val memberQ = selectSimple(
      Seq(uId, uLogin),
      from,
      and(mSpaceId.is(id), sColl.is(collective))
    ).query[IdRef].to[Vector]

    (for {
      space <- OptionT(findAll(collective, Some(id), None, None).map(_.headOption))
      memb  <- OptionT.liftF(memberQ)
    } yield space.withMembers(memb.toList)).value
  }

  def findAll(
      collective: Ident,
      idQ: Option[Ident],
      ownerLogin: Option[Ident],
      nameQ: Option[String]
  ): ConnectionIO[Vector[SpaceItem]] = {
    val uId    = RUser.Columns.uid.prefix("u")
    val uLogin = RUser.Columns.login.prefix("u")
    val sId    = RSpace.Columns.id.prefix("s")
    val sOwner = RSpace.Columns.owner.prefix("s")
    val sName  = RSpace.Columns.name.prefix("s")
    val sColl  = RSpace.Columns.collective.prefix("s")
    val cols = Seq(
      sId,
      sName,
      uId,
      RUser.Columns.login.prefix("u"),
      RSpace.Columns.created.prefix("s")
    )

    val from = RSpace.table ++ fr"s INNER JOIN" ++
      RUser.table ++ fr"u ON" ++ uId.is(sOwner)

    val where =
      sColl.is(collective) :: idQ.toList.map(id => sId.is(id)) ::: nameQ.toList.map(q =>
        sName.lowerLike(s"%${q.toLowerCase}%")
      ) ::: ownerLogin.toList.map(login => uLogin.is(login))

    selectSimple(cols, from, and(where) ++ orderBy(sName.asc)).query[SpaceItem].to[Vector]
  }

  private def findUserId(account: AccountId): ConnectionIO[Option[Ident]] =
    RUser.findByAccount(account).map(_.map(_.uid))
}
