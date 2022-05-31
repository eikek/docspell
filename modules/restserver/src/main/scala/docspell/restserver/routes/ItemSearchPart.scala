/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import java.time.LocalDate

import cats.effect._
import cats.syntax.all._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.search.QueryParseResult
import docspell.common.{SearchMode, Timestamp}
import docspell.query.FulltextExtract
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s.{QueryParam => QP}
import docspell.store.qb.Batch
import docspell.store.queries.ListItemWithTags

import org.http4s.circe.CirceEntityCodec._
import org.http4s.dsl.Http4sDsl
import org.http4s.{HttpRoutes, Response}

final class ItemSearchPart[F[_]: Async](
    backend: BackendApp[F],
    cfg: Config,
    authToken: AuthToken
) extends Http4sDsl[F] {

  private[this] val logger = docspell.logging.getLogger[F]

  def routes: HttpRoutes[F] =
    if (!cfg.featureSearch2) HttpRoutes.empty
    else
      HttpRoutes.of {
        case GET -> Root / "search" :? QP.Query(q) :? QP.Limit(limit) :? QP.Offset(
              offset
            ) :? QP.WithDetails(detailFlag) :? QP.SearchKind(searchMode) =>
          val userQuery =
            ItemQuery(offset, limit, detailFlag, searchMode, q.getOrElse(""))

          Timestamp
            .current[F]
            .map(_.toUtcDate)
            .flatMap(search(userQuery, _))

        case req @ POST -> Root / "search" =>
          for {
            userQuery <- req.as[ItemQuery]
            today <- Timestamp.current[F]
            resp <- search(userQuery, today.toUtcDate)
          } yield resp

        case GET -> Root / "searchStats" :? QP.Query(q) :? QP.SearchKind(searchMode) =>
          val userQuery = ItemQuery(None, None, None, searchMode, q.getOrElse(""))
          Timestamp
            .current[F]
            .map(_.toUtcDate)
            .flatMap(searchStats(userQuery, _))

        case req @ POST -> Root / "searchStats" =>
          for {
            userQuery <- req.as[ItemQuery]
            today <- Timestamp.current[F].map(_.toUtcDate)
            resp <- searchStats(userQuery, today)
          } yield resp
      }

  def searchStats(userQuery: ItemQuery, today: LocalDate): F[Response[F]] = {
    val mode = userQuery.searchMode.getOrElse(SearchMode.Normal)
    parsedQuery(userQuery, mode)
      .fold(
        identity,
        res =>
          for {
            summary <- backend.search.searchSummary(today)(res.q, res.ftq)
            resp <- Ok(Conversions.mkSearchStats(summary))
          } yield resp
      )
  }

  def search(userQuery: ItemQuery, today: LocalDate): F[Response[F]] = {
    val details = userQuery.withDetails.getOrElse(false)
    val batch =
      Batch(userQuery.offset.getOrElse(0), userQuery.limit.getOrElse(cfg.maxItemPageSize))
        .restrictLimitTo(cfg.maxItemPageSize)
    val limitCapped = userQuery.limit.exists(_ > cfg.maxItemPageSize)
    val mode = userQuery.searchMode.getOrElse(SearchMode.Normal)

    parsedQuery(userQuery, mode)
      .fold(
        identity,
        res =>
          for {
            items <- backend.search
              .searchSelect(details, cfg.maxNoteLength, today, batch)(
                res.q,
                res.ftq
              )

            // order is always by date unless q is empty and ftq is not
            // TODO this is not obvious from the types and an impl detail.
            ftsOrder = res.q.cond.isEmpty && res.ftq.isDefined

            resp <- Ok(convert(items, batch, limitCapped, ftsOrder))
          } yield resp
      )
  }

  def parsedQuery(
      userQuery: ItemQuery,
      mode: SearchMode
  ): Either[F[Response[F]], QueryParseResult.Success] =
    backend.search.parseQueryString(authToken.account, mode, userQuery.query) match {
      case s: QueryParseResult.Success =>
        Right(s)

      case QueryParseResult.ParseFailed(err) =>
        Left(BadRequest(BasicResult(false, s"Invalid query: $err")))

      case QueryParseResult.FulltextMismatch(FulltextExtract.Result.TooMany) =>
        Left(
          BadRequest(
            BasicResult(false, "Only one fulltext search expression is allowed.")
          )
        )
      case QueryParseResult.FulltextMismatch(
            FulltextExtract.Result.UnsupportedPosition
          ) =>
        Left(
          BadRequest(
            BasicResult(
              false,
              "A fulltext search may only appear in the root and expression."
            )
          )
        )
    }

  def convert(
      items: Vector[ListItemWithTags],
      batch: Batch,
      capped: Boolean,
      ftsOrder: Boolean
  ): ItemLightList =
    if (ftsOrder)
      ItemLightList(
        List(ItemLightGroup("Results", items.map(convertItem).toList)),
        batch.limit,
        batch.offset,
        capped
      )
    else {
      val groups = items.groupBy(ti => ti.item.date.toUtcDate.toString.substring(0, 7))

      def mkGroup(g: (String, Vector[ListItemWithTags])): ItemLightGroup =
        ItemLightGroup(g._1, g._2.map(convertItem).toList)

      val gs =
        groups.map(mkGroup).toList.sortWith((g1, g2) => g1.name.compareTo(g2.name) >= 0)

      ItemLightList(gs, batch.limit, batch.offset, capped)
    }

  def convertItem(item: ListItemWithTags): ItemLight =
    ItemLight(
      id = item.item.id,
      name = item.item.name,
      state = item.item.state,
      date = item.item.date,
      dueDate = item.item.dueDate,
      source = item.item.source,
      direction = item.item.direction.name.some,
      corrOrg = item.item.corrOrg.map(Conversions.mkIdName),
      corrPerson = item.item.corrPerson.map(Conversions.mkIdName),
      concPerson = item.item.concPerson.map(Conversions.mkIdName),
      concEquipment = item.item.concEquip.map(Conversions.mkIdName),
      folder = item.item.folder.map(Conversions.mkIdName),
      attachments = item.attachments.map(Conversions.mkAttachmentLight),
      tags = item.tags.map(Conversions.mkTag),
      customfields = item.customfields.map(Conversions.mkItemFieldValue),
      relatedItems = item.relatedItems,
      notes = item.item.notes,
      highlighting = item.item.decodeContext match {
        case Some(Right(hlctx)) =>
          hlctx.map(c => HighlightEntry(c.name, c.context))
        case Some(Left(err)) =>
          logger.asUnsafe.error(
            s"Internal error: cannot decode highlight context '${item.item.context}': $err"
          )
          Nil
        case None =>
          Nil
      }
    )
}

object ItemSearchPart {
  def apply[F[_]: Async](
      backend: BackendApp[F],
      cfg: Config,
      token: AuthToken
  ): ItemSearchPart[F] =
    new ItemSearchPart[F](backend, cfg, token)
}
