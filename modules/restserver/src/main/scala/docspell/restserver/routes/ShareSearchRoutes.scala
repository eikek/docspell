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
import docspell.backend.ops.OSimpleSearch.StringSearchResult
import docspell.common._
import docspell.query.FulltextExtract.Result.{TooMany, UnsupportedPosition}
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions
import docspell.store.qb.Batch
import docspell.store.queries.{Query, SearchSummary}

import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.{HttpRoutes, Response}

object ShareSearchRoutes {

  def apply[F[_]: Async](
      backend: BackendApp[F],
      cfg: Config,
      token: ShareToken
  ): HttpRoutes[F] = {
    val logger = Logger.log4s[F](org.log4s.getLogger)

    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ POST -> Root / "query" =>
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
              account = share.account
              fixQuery = Query.Fix(account, Some(share.query.expr), None)
              _ <- logger.debug(s"Searching in share ${share.id.id}: ${userQuery.query}")
              resp <- ItemRoutes.searchItems(backend, dsl)(settings, fixQuery, itemQuery)
            } yield resp
          }
          .getOrElseF(NotFound())

      case req @ POST -> Root / "stats" =>
        for {
          userQuery <- req.as[ItemQuery]
          itemQuery = ItemQueryString(userQuery.query)
          settings = OSimpleSearch.StatsSettings(
            useFTS = cfg.fullTextSearch.enabled,
            searchMode = userQuery.searchMode.getOrElse(SearchMode.Normal)
          )
          stats <- backend.share.searchSummary(settings)(token.id, itemQuery).value
          resp <- stats.map(mkSummaryResponse(dsl)).getOrElse(NotFound())
        } yield resp
    }
  }

  def mkSummaryResponse[F[_]: Sync](
      dsl: Http4sDsl[F]
  )(r: StringSearchResult[SearchSummary]): F[Response[F]] = {
    import dsl._
    r match {
      case StringSearchResult.Success(summary) =>
        Ok(Conversions.mkSearchStats(summary))
      case StringSearchResult.FulltextMismatch(TooMany) =>
        BadRequest(BasicResult(false, "Fulltext search is not possible in this share."))
      case StringSearchResult.FulltextMismatch(UnsupportedPosition) =>
        BadRequest(
          BasicResult(
            false,
            "Fulltext search must be in root position or inside the first AND."
          )
        )
      case StringSearchResult.ParseFailed(pf) =>
        BadRequest(BasicResult(false, s"Error reading query: ${pf.render}"))
    }
  }

}
