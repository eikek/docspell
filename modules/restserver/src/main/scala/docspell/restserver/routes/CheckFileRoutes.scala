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
import docspell.common.Ident
import docspell.restapi.model.{BasicItem, CheckFileResult}
import docspell.restserver.http4s.ResponseGenerator
import docspell.store.records.RItem

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object CheckFileRoutes {

  def secured[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of { case GET -> Root / checksum =>
      for {
        items <-
          backend.itemSearch.findByFileCollective(checksum, user.account.collective)
        resp <- Ok(convert(items))
      } yield resp

    }
  }

  def open[F[_]: Async](backend: BackendApp[F]): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of { case GET -> Root / Ident(id) / checksum =>
      for {
        items <- backend.itemSearch.findByFileSource(checksum, id)
        resp  <- items.map(convert).map(Ok(_)).getOrElse(NotFound())
      } yield resp
    }
  }

  def convert(v: Vector[RItem]): CheckFileResult =
    CheckFileResult(
      v.nonEmpty,
      v.map(r => BasicItem(r.id, r.name, r.direction, r.state, r.created, r.itemDate))
        .toList
    )

}
