/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import cats.data.OptionT
import cats.data.{NonEmptyList => Nel}
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
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

  def delete(id: Ident, userId: Ident): ConnectionIO[FolderChangeResult] = {
    def tryDelete =
      for {
        _ <- RItem.removeFolder(id)
        _ <- RSource.removeFolder(id)
        _ <- RFolderMember.deleteAll(id)
        _ <- RFolder.delete(id)
      } yield FolderChangeResult.success

    (for {
      folder <- OptionT(RFolder.findById(id))
      res <- OptionT.liftF(
        if (folder.owner == userId) tryDelete
        else FolderChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(FolderChangeResult.notFound)
  }

  def changeName(
      folder: Ident,
      userId: Ident,
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
      folder <- OptionT(RFolder.findById(folder))
      res <- OptionT.liftF(
        if (folder.owner == userId) tryUpdate(folder.copy(name = name))
        else FolderChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(FolderChangeResult.notFound)
  }

  def removeMember(
      folder: Ident,
      userId: Ident,
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
      folder <- OptionT(RFolder.findById(folder))
      res <- OptionT.liftF(
        if (folder.owner == userId) tryRemove
        else FolderChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(FolderChangeResult.notFound)
  }

  def addMember(
      folder: Ident,
      userId: Ident,
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
      folder <- OptionT(RFolder.findById(folder))
      res <- OptionT.liftF(
        if (folder.owner == userId) tryAdd
        else FolderChangeResult.forbidden.pure[ConnectionIO]
      )
    } yield res).getOrElse(FolderChangeResult.notFound)
  }

  def findById(
      id: Ident,
      collectiveId: CollectiveId,
      userId: Ident
  ): ConnectionIO[Option[FolderDetail]] = {
    val user = RUser.as("u")
    val member = RFolderMember.as("m")
    val folder = RFolder.as("s")

    val memberQ = run(
      select(user.uid, user.login),
      from(member)
        .innerJoin(user, member.user === user.uid)
        .innerJoin(folder, member.folder === folder.id),
      member.folder === id && folder.collective === collectiveId
    ).query[IdRef].to[Vector]

    (for {
      folder <- OptionT(
        findAll(
          collectiveId,
          userId,
          Some(id),
          None,
          None,
          (ft, _) => Nel.of(ft.name.asc)
        )
          .map(_.headOption)
      )
      memb <- OptionT.liftF(memberQ)
    } yield folder.withMembers(memb.toList)).value
  }

  def findAll(
      collectiveId: CollectiveId,
      userId: Ident,
      idQ: Option[Ident],
      ownerLogin: Option[Ident],
      nameQ: Option[String],
      order: (RFolder.Table, RUser.Table) => Nel[OrderBy]
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

    val user = RUser.as("u")
    val member = RFolderMember.as("m")
    val folder = RFolder.as("s")
    val memlogin = TableDef("memberlogin")
    val mlFolder = Column[Ident]("folder", memlogin)
    val mlUser = Column[Ident]("user_id", memlogin)

    withCte(
      memlogin -> union(
        Select(
          select(member.folder.as(mlFolder), member.user.as(mlUser)),
          from(member)
            .innerJoin(folder, folder.id === member.folder),
          folder.collective === collectiveId
        ),
        Select(
          select(folder.id.as(mlFolder), folder.owner.as(mlUser)),
          from(folder),
          folder.collective === collectiveId
        )
      )
    )(
      Select(
        select(
          folder.id.s,
          folder.name.s,
          folder.owner.s,
          user.login.s,
          folder.created.s,
          Select(
            select(countAll > 0),
            from(memlogin),
            mlFolder === folder.id && mlUser === userId
          ).as("member"),
          Select(
            select(countAll - 1),
            from(memlogin),
            mlFolder === folder.id
          ).as("member_count")
        ),
        from(folder)
          .innerJoin(user, user.uid === folder.owner),
        where(
          folder.collective === collectiveId &&?
            idQ.map(id => folder.id === id) &&?
            nameQ.map(q => folder.name.like(s"%${q.toLowerCase}%")) &&?
            ownerLogin.map(login => user.login === login)
        )
      ).orderBy(order(folder, user))
    ).build.query[FolderItem].to[Vector]
  }

  /** Select all folder_id where the given account is member or owner. */
  def findMemberFolderIds(cid: CollectiveId, userId: Ident): Select = {
    val user = RUser.as("u")
    val f = RFolder.as("f")
    val m = RFolderMember.as("m")
    union(
      Select(
        select(f.id),
        from(f).innerJoin(user, f.owner === user.uid),
        f.collective === cid && user.uid === userId
      ),
      Select(
        select(m.folder),
        from(m)
          .innerJoin(f, f.id === m.folder)
          .innerJoin(user, user.uid === m.user),
        f.collective === cid && user.uid === userId
      )
    )
  }

  def getMemberFolders(
      collectiveId: CollectiveId,
      userId: Ident
  ): ConnectionIO[Set[Ident]] =
    findMemberFolderIds(collectiveId, userId).build.query[Ident].to[Set]
}
