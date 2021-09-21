/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OFolder
import docspell.common._
import docspell.restapi.model._
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s._
import docspell.store.records.RFolder

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object FolderRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root :? QueryParam.QueryOpt(q) :?
          QueryParam.OwningOpt(owning) +& QueryParam.FolderSort(sort) =>
        val order = sort.getOrElse(OFolder.FolderOrder.NameAsc)
        val login =
          owning.filter(identity).map(_ => user.account.user)
        for {
          all  <- backend.folder.findAll(user.account, login, q.map(_.q), order)
          resp <- Ok(FolderList(all.map(mkFolder).toList))
        } yield resp

      case req @ POST -> Root =>
        for {
          data    <- req.as[NewFolder]
          nfolder <- newFolder(data, user.account)
          res     <- backend.folder.add(nfolder, Some(user.account.user))
          resp <-
            Ok(Conversions.idResult(res, nfolder.id, "Folder successfully created."))
        } yield resp

      case GET -> Root / Ident(id) =>
        (for {
          folder <- OptionT(backend.folder.findById(id, user.account))
          resp   <- OptionT.liftF(Ok(mkFolderDetail(folder)))
        } yield resp).getOrElseF(NotFound())

      case req @ PUT -> Root / Ident(id) =>
        for {
          data <- req.as[NewFolder]
          res  <- backend.folder.changeName(id, user.account, data.name)
          resp <- Ok(mkFolderChangeResult(res))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          res  <- backend.folder.delete(id, user.account)
          resp <- Ok(mkFolderChangeResult(res))
        } yield resp

      case PUT -> Root / Ident(id) / "member" / Ident(userId) =>
        for {
          res  <- backend.folder.addMember(id, user.account, userId)
          resp <- Ok(mkFolderChangeResult(res))
        } yield resp

      case DELETE -> Root / Ident(id) / "member" / Ident(userId) =>
        for {
          res  <- backend.folder.removeMember(id, user.account, userId)
          resp <- Ok(mkFolderChangeResult(res))
        } yield resp
    }
  }

  private def newFolder[F[_]: Sync](ns: NewFolder, account: AccountId): F[RFolder] =
    RFolder.newFolder(ns.name, account)

  private def mkFolder(item: OFolder.FolderItem): FolderItem =
    FolderItem(
      item.id,
      item.name,
      Conversions.mkIdName(item.owner),
      item.created,
      item.member,
      item.memberCount
    )

  private def mkFolderDetail(item: OFolder.FolderDetail): FolderDetail =
    FolderDetail(
      item.id,
      item.name,
      Conversions.mkIdName(item.owner),
      item.created,
      item.member,
      item.memberCount,
      item.members.map(Conversions.mkIdName)
    )

  private def mkFolderChangeResult(r: OFolder.FolderChangeResult): BasicResult =
    r match {
      case OFolder.FolderChangeResult.Success =>
        BasicResult(true, "Successfully changed folder.")
      case OFolder.FolderChangeResult.NotFound =>
        BasicResult(false, "Folder or user not found.")
      case OFolder.FolderChangeResult.Forbidden =>
        BasicResult(false, "Not allowed to edit folder.")
      case OFolder.FolderChangeResult.Exists =>
        BasicResult(false, "The member already exists.")
    }
}
