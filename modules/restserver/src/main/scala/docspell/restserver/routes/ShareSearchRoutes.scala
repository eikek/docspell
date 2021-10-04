/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.ShareToken
import docspell.backend.ops.OSimpleSearch
import docspell.common._
import docspell.restapi.model.ItemQuery
import docspell.restserver.Config
import docspell.store.qb.Batch
import docspell.store.queries.Query

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.dsl.Http4sDsl

object ShareSearchRoutes {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      cfg: Config,
      token: ShareToken
  ): HttpRoutes[F] = {
    val logger = Logger.log4s[F](org.log4s.getLogger)

    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root =>
      backend.share
        .findShareQuery(token.id)
        .semiflatMap { share =>
          for {
            userQuery <- req.as[ItemQuery]
            batch = Batch(
              userQuery.offset.getOrElse(0),
              userQuery.limit.getOrElse(cfg.maxItemPageSize)
            ).restrictLimitTo(
              cfg.maxItemPageSize
            )
            itemQuery = ItemQueryString(userQuery.query)
            settings = OSimpleSearch.Settings(
              batch,
              cfg.fullTextSearch.enabled,
              userQuery.withDetails.getOrElse(false),
              cfg.maxNoteLength,
              searchMode = SearchMode.Normal
            )
            account = AccountId(share.cid, Ident.unsafe(""))
            fixQuery = Query.Fix(account, Some(share.query.expr), None)
            _ <- logger.debug(s"Searching in share ${share.id.id}: ${userQuery.query}")
            resp <- ItemRoutes.searchItems(backend, dsl)(settings, fixQuery, itemQuery)
          } yield resp
        }
        .getOrElseF(NotFound())
    }
  }
}
