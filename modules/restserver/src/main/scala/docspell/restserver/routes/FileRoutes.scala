/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.syntax.all._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.common._
import docspell.restapi.model.BasicResult
import docspell.restserver.http4s.BinaryUtil

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object FileRoutes {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case HEAD -> Root / collStr / catStr / Ident(fid) =>
        parseFileKey(collStr, catStr, fid) match {
          case Right(key) =>
            for {
              fileData <- backend.itemSearch.findFile(key, user.account.collectiveId)
              resp <- BinaryUtil.respondHead(dsl)(fileData)
            } yield resp
          case Left(msg) =>
            BadRequest(BasicResult(success = false, msg))
        }

      case req @ GET -> Root / collStr / catStr / Ident(fid) =>
        parseFileKey(collStr, catStr, fid) match {
          case Right(key) =>
            for {
              fileData <- backend.itemSearch.findFile(key, user.account.collectiveId)
              resp <- BinaryUtil.respond(dsl, req)(fileData)
            } yield resp
          case Left(msg) =>
            BadRequest(BasicResult(success = false, msg))
        }
    }
  }

  private def parseFileKey(
      collStr: String,
      catStr: String,
      fid: Ident
  ): Either[String, FileKey] =
    for {
      cid <- CollectiveId.fromString(collStr)
      cat <- FileCategory.fromString(catStr)
    } yield FileKey(cid, cat, fid)
}
