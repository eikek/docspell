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
      created: Timestamp,
      member: Boolean,
      memberCount: Int
  ) {
    def withMembers(members: List[IdRef]): SpaceDetail =
      SpaceDetail(id, name, owner, created, member, memberCount, members)
  }

  final case class SpaceDetail(
      id: Ident,
      name: String,
      owner: IdRef,
      created: Timestamp,
      member: Boolean,
      memberCount: Int,
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

  def findById(id: Ident, account: AccountId): ConnectionIO[Option[SpaceDetail]] = {
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
      and(mSpaceId.is(id), sColl.is(account.collective))
    ).query[IdRef].to[Vector]

    (for {
      space <- OptionT(findAll(account, Some(id), None, None).map(_.headOption))
      memb  <- OptionT.liftF(memberQ)
    } yield space.withMembers(memb.toList)).value
  }

  def findAll(
      account: AccountId,
      idQ: Option[Ident],
      ownerLogin: Option[Ident],
      nameQ: Option[String]
  ): ConnectionIO[Vector[SpaceItem]] = {
// with memberlogin as
//   (select m.space_id,u.login
//    from space_member m
//    inner join user_ u on u.uid = m.user_id
//    inner join space s on s.id = m.space_id
//    where s.cid = 'eike'
//    union all
//    select s.id,u.login
//    from space s
//    inner join user_ u on u.uid = s.owner
//    where s.cid = 'eike')
// select s.id
//       ,s.name
//       ,s.owner
//       ,u.login
//       ,s.created
//       ,(select count(*) > 0 from memberlogin where space_id = s.id and login = 'eike') as member
//       ,(select count(*) - 1 from memberlogin where space_id = s.id) as member_count
// from space s
// inner join user_ u on u.uid = s.owner
// where s.cid = 'eike';

    val uId    = RUser.Columns.uid.prefix("u")
    val uLogin = RUser.Columns.login.prefix("u")
    val sId    = RSpace.Columns.id.prefix("s")
    val sOwner = RSpace.Columns.owner.prefix("s")
    val sName  = RSpace.Columns.name.prefix("s")
    val sColl  = RSpace.Columns.collective.prefix("s")
    val mUser  = RSpaceMember.Columns.user.prefix("m")
    val mSpace = RSpaceMember.Columns.space.prefix("m")

    //CTE
    val cte: Fragment = {
      val from1 = RSpaceMember.table ++ fr"m INNER JOIN" ++
        RUser.table ++ fr"u ON" ++ uId.is(mUser) ++ fr"INNER JOIN" ++
        RSpace.table ++ fr"s ON" ++ sId.is(mSpace)

      val from2 = RSpace.table ++ fr"s INNER JOIN" ++
        RUser.table ++ fr"u ON" ++ uId.is(sOwner)

      withCTE(
        "memberlogin" ->
          (selectSimple(Seq(mSpace, uLogin), from1, sColl.is(account.collective)) ++
            fr"UNION ALL" ++
            selectSimple(Seq(sId, uLogin), from2, sColl.is(account.collective)))
      )
    }

    val isMember =
      fr"SELECT COUNT(*) > 0 FROM memberlogin WHERE" ++ mSpace.prefix("").is(sId) ++
        fr"AND" ++ uLogin.prefix("").is(account.user)

    val memberCount =
      fr"SELECT COUNT(*) - 1 FROM memberlogin WHERE" ++ mSpace.prefix("").is(sId)

    //Query
    val cols = Seq(
      sId.f,
      sName.f,
      sOwner.f,
      uLogin.f,
      RSpace.Columns.created.prefix("s").f,
      fr"(" ++ isMember ++ fr") as mem",
      fr"(" ++ memberCount ++ fr") as cnt"
    )

    val from = RSpace.table ++ fr"s INNER JOIN" ++
      RUser.table ++ fr"u ON" ++ uId.is(sOwner)

    val where =
      sColl.is(account.collective) :: idQ.toList
        .map(id => sId.is(id)) ::: nameQ.toList.map(q =>
        sName.lowerLike(s"%${q.toLowerCase}%")
      ) ::: ownerLogin.toList.map(login => uLogin.is(login))

    (cte ++ selectSimple(commas(cols), from, and(where) ++ orderBy(sName.asc)))
      .query[SpaceItem]
      .to[Vector]
  }

  private def findUserId(account: AccountId): ConnectionIO[Option[Ident]] =
    RUser.findByAccount(account).map(_.map(_.uid))
}
