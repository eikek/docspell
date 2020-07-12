package docspell.store.queries

import cats.data.OptionT
import cats.implicits._

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.records._

import doobie._
import doobie.implicits._

object QFolder {

  final case class FolderItem(
      id: Ident,
      name: String,
      owner: IdRef,
      created: Timestamp,
      member: Boolean,
      memberCount: Int
  ) {
    def withMembers(members: List[IdRef]): FolderDetail =
      FolderDetail(id, name, owner, created, member, memberCount, members)
  }

  final case class FolderDetail(
      id: Ident,
      name: String,
      owner: IdRef,
      created: Timestamp,
      member: Boolean,
      memberCount: Int,
      members: List[IdRef]
  )

  sealed trait FolderChangeResult
  object FolderChangeResult {
    case object Success extends FolderChangeResult
    def success: FolderChangeResult = Success
    case object NotFound extends FolderChangeResult
    def notFound: FolderChangeResult = NotFound
    case object Forbidden extends FolderChangeResult
    def forbidden: FolderChangeResult = Forbidden
    case object Exists extends FolderChangeResult
    def exists: FolderChangeResult = Exists
  }

  def delete(id: Ident, account: AccountId): ConnectionIO[FolderChangeResult] = {
    def tryDelete =
      for {
        _ <- RItem.removeFolder(id)
        _ <- RFolderMember.deleteAll(id)
        _ <- RFolder.delete(id)
      } yield FolderChangeResult.success

    (for {
      uid    <- OptionT(findUserId(account))
      folder <- OptionT(RFolder.findById(id))
      res <- OptionT.liftF(
        if (folder.owner == uid) tryDelete
        else FolderChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(FolderChangeResult.notFound)
  }

  def changeName(
      folder: Ident,
      account: AccountId,
      name: String
  ): ConnectionIO[FolderChangeResult] = {
    def tryUpdate(ns: RFolder): ConnectionIO[FolderChangeResult] =
      for {
        n <- RFolder.update(ns)
        res =
          if (n == 0) FolderChangeResult.notFound
          else FolderChangeResult.Success
      } yield res

    (for {
      uid    <- OptionT(findUserId(account))
      folder <- OptionT(RFolder.findById(folder))
      res <- OptionT.liftF(
        if (folder.owner == uid) tryUpdate(folder.copy(name = name))
        else FolderChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(FolderChangeResult.notFound)
  }

  def removeMember(
      folder: Ident,
      account: AccountId,
      member: Ident
  ): ConnectionIO[FolderChangeResult] = {
    def tryRemove: ConnectionIO[FolderChangeResult] =
      for {
        n <- RFolderMember.delete(member, folder)
        res =
          if (n == 0) FolderChangeResult.notFound
          else FolderChangeResult.Success
      } yield res

    (for {
      uid    <- OptionT(findUserId(account))
      folder <- OptionT(RFolder.findById(folder))
      res <- OptionT.liftF(
        if (folder.owner == uid) tryRemove
        else FolderChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(FolderChangeResult.notFound)
  }

  def addMember(
      folder: Ident,
      account: AccountId,
      member: Ident
  ): ConnectionIO[FolderChangeResult] = {
    def tryAdd: ConnectionIO[FolderChangeResult] =
      for {
        spm <- RFolderMember.findByUserId(member, folder)
        mem <- RFolderMember.newMember[ConnectionIO](folder, member)
        res <-
          if (spm.isDefined) FolderChangeResult.exists.pure[ConnectionIO]
          else RFolderMember.insert(mem).map(_ => FolderChangeResult.Success)
      } yield res

    (for {
      uid    <- OptionT(findUserId(account))
      folder <- OptionT(RFolder.findById(folder))
      res <- OptionT.liftF(
        if (folder.owner == uid) tryAdd
        else FolderChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(FolderChangeResult.notFound)
  }

  def findById(id: Ident, account: AccountId): ConnectionIO[Option[FolderDetail]] = {
    val mUserId   = RFolderMember.Columns.user.prefix("m")
    val mFolderId = RFolderMember.Columns.folder.prefix("m")
    val uId       = RUser.Columns.uid.prefix("u")
    val uLogin    = RUser.Columns.login.prefix("u")
    val sColl     = RFolder.Columns.collective.prefix("s")
    val sId       = RFolder.Columns.id.prefix("s")

    val from = RFolderMember.table ++ fr"m INNER JOIN" ++
      RUser.table ++ fr"u ON" ++ mUserId.is(uId) ++ fr"INNER JOIN" ++
      RFolder.table ++ fr"s ON" ++ mFolderId.is(sId)

    val memberQ = selectSimple(
      Seq(uId, uLogin),
      from,
      and(mFolderId.is(id), sColl.is(account.collective))
    ).query[IdRef].to[Vector]

    (for {
      folder <- OptionT(findAll(account, Some(id), None, None).map(_.headOption))
      memb   <- OptionT.liftF(memberQ)
    } yield folder.withMembers(memb.toList)).value
  }

  def findAll(
      account: AccountId,
      idQ: Option[Ident],
      ownerLogin: Option[Ident],
      nameQ: Option[String]
  ): ConnectionIO[Vector[FolderItem]] = {
// with memberlogin as
//   (select m.folder_id,u.login
//    from folder_member m
//    inner join user_ u on u.uid = m.user_id
//    inner join folder s on s.id = m.folder_id
//    where s.cid = 'eike'
//    union all
//    select s.id,u.login
//    from folder s
//    inner join user_ u on u.uid = s.owner
//    where s.cid = 'eike')
// select s.id
//       ,s.name
//       ,s.owner
//       ,u.login
//       ,s.created
//       ,(select count(*) > 0 from memberlogin where folder_id = s.id and login = 'eike') as member
//       ,(select count(*) - 1 from memberlogin where folder_id = s.id) as member_count
// from folder s
// inner join user_ u on u.uid = s.owner
// where s.cid = 'eike';

    val uId     = RUser.Columns.uid.prefix("u")
    val uLogin  = RUser.Columns.login.prefix("u")
    val sId     = RFolder.Columns.id.prefix("s")
    val sOwner  = RFolder.Columns.owner.prefix("s")
    val sName   = RFolder.Columns.name.prefix("s")
    val sColl   = RFolder.Columns.collective.prefix("s")
    val mUser   = RFolderMember.Columns.user.prefix("m")
    val mFolder = RFolderMember.Columns.folder.prefix("m")

    //CTE
    val cte: Fragment = {
      val from1 = RFolderMember.table ++ fr"m INNER JOIN" ++
        RUser.table ++ fr"u ON" ++ uId.is(mUser) ++ fr"INNER JOIN" ++
        RFolder.table ++ fr"s ON" ++ sId.is(mFolder)

      val from2 = RFolder.table ++ fr"s INNER JOIN" ++
        RUser.table ++ fr"u ON" ++ uId.is(sOwner)

      withCTE(
        "memberlogin" ->
          (selectSimple(Seq(mFolder, uLogin), from1, sColl.is(account.collective)) ++
            fr"UNION ALL" ++
            selectSimple(Seq(sId, uLogin), from2, sColl.is(account.collective)))
      )
    }

    val isMember =
      fr"SELECT COUNT(*) > 0 FROM memberlogin WHERE" ++ mFolder.prefix("").is(sId) ++
        fr"AND" ++ uLogin.prefix("").is(account.user)

    val memberCount =
      fr"SELECT COUNT(*) - 1 FROM memberlogin WHERE" ++ mFolder.prefix("").is(sId)

    //Query
    val cols = Seq(
      sId.f,
      sName.f,
      sOwner.f,
      uLogin.f,
      RFolder.Columns.created.prefix("s").f,
      fr"(" ++ isMember ++ fr") as mem",
      fr"(" ++ memberCount ++ fr") as cnt"
    )

    val from = RFolder.table ++ fr"s INNER JOIN" ++
      RUser.table ++ fr"u ON" ++ uId.is(sOwner)

    val where =
      sColl.is(account.collective) :: idQ.toList
        .map(id => sId.is(id)) ::: nameQ.toList.map(q =>
        sName.lowerLike(s"%${q.toLowerCase}%")
      ) ::: ownerLogin.toList.map(login => uLogin.is(login))

    (cte ++ selectSimple(commas(cols), from, and(where) ++ orderBy(sName.asc)))
      .query[FolderItem]
      .to[Vector]
  }

  /** Select all folder_id where the given account is member or owner. */
  def findMemberFolderIds(account: AccountId): Fragment = {
    val fId     = RFolder.Columns.id.prefix("f")
    val fOwner  = RFolder.Columns.owner.prefix("f")
    val fColl   = RFolder.Columns.collective.prefix("f")
    val uId     = RUser.Columns.uid.prefix("u")
    val uLogin  = RUser.Columns.login.prefix("u")
    val mFolder = RFolderMember.Columns.folder.prefix("m")
    val mUser   = RFolderMember.Columns.user.prefix("m")

    selectSimple(
      Seq(fId),
      RFolder.table ++ fr"f INNER JOIN" ++ RUser.table ++ fr"u ON" ++ fOwner.is(uId),
      and(fColl.is(account.collective), uLogin.is(account.user))
    ) ++
      fr"UNION ALL" ++
      selectSimple(
        Seq(mFolder),
        RFolderMember.table ++ fr"m INNER JOIN" ++ RFolder.table ++ fr"f ON" ++ fId.is(
          mFolder
        ) ++
          fr"INNER JOIN" ++ RUser.table ++ fr"u ON" ++ uId.is(mUser),
        and(fColl.is(account.collective), uLogin.is(account.user))
      )
  }

  def getMemberFolders(account: AccountId): ConnectionIO[Set[Ident]] =
    findMemberFolderIds(account).query[Ident].to[Set]

  private def findUserId(account: AccountId): ConnectionIO[Option[Ident]] =
    RUser.findByAccount(account).map(_.map(_.uid))
}
