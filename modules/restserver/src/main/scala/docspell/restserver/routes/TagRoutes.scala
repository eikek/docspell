/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OTag.TagOrder
import docspell.common.Ident
import docspell.restapi.model._
import docspell.restserver.conv.Conversions._
import docspell.restserver.http4s._

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object TagRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root :? QueryParam.QueryOpt(q) :? QueryParam.TagSort(sort) =>
        for {
          all <- backend.tag.findAll(
            user.account.collectiveId,
            q.map(_.q),
            sort.getOrElse(TagOrder.NameAsc)
          )
          resp <- Ok(TagList(all.size, all.map(mkTag).toList))
        } yield resp

      case req @ POST -> Root =>
        for {
          data <- req.as[Tag]
          tag <- newTag(data, user.account.collectiveId)
          res <- backend.tag.add(tag)
          resp <- Ok(basicResult(res, "Tag successfully created."))
        } yield resp

      case req @ PUT -> Root =>
        for {
          data <- req.as[Tag]
          tag = changeTag(data, user.account.collectiveId)
          res <- backend.tag.update(tag)
          resp <- Ok(basicResult(res, "Tag successfully updated."))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          del <- backend.tag.delete(id, user.account.collectiveId)
          resp <- Ok(basicResult(del, "Tag successfully deleted."))
        } yield resp
    }
  }

}
