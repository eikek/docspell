/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OCustomFields.{RemoveValue, SetValue}
import docspell.backend.ops.OFulltext
import docspell.backend.ops.OItemSearch.{Batch, Query}
import docspell.backend.ops.OSimpleSearch
import docspell.backend.ops.OSimpleSearch.StringSearchResult
import docspell.common._
import docspell.common.syntax.all._
import docspell.query.FulltextExtract.Result.TooMany
import docspell.query.FulltextExtract.Result.UnsupportedPosition
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s.BinaryUtil
import docspell.restserver.http4s.Responses
import docspell.restserver.http4s.{QueryParam => QP}

import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._
import org.http4s.{HttpRoutes, Response}
import org.log4s._

object ItemRoutes {
  private[this] val logger = getLogger

  def apply[F[_]: Async](
      cfg: Config,
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root / "search" :? QP.Query(q) :? QP.Limit(limit) :? QP.Offset(
            offset
          ) :? QP.WithDetails(detailFlag) :? QP.SearchKind(searchMode) =>
        val batch = Batch(offset.getOrElse(0), limit.getOrElse(cfg.maxItemPageSize))
          .restrictLimitTo(cfg.maxItemPageSize)
        val itemQuery = ItemQueryString(q)
        val settings = OSimpleSearch.Settings(
          batch,
          cfg.fullTextSearch.enabled,
          detailFlag.getOrElse(false),
          cfg.maxNoteLength,
          searchMode.getOrElse(SearchMode.Normal)
        )
        val fixQuery = Query.Fix(user.account, None, None)
        searchItems(backend, dsl)(settings, fixQuery, itemQuery)

      case GET -> Root / "searchStats" :? QP.Query(q) :? QP.SearchKind(searchMode) =>
        val itemQuery = ItemQueryString(q)
        val fixQuery = Query.Fix(user.account, None, None)
        val settings = OSimpleSearch.StatsSettings(
          useFTS = cfg.fullTextSearch.enabled,
          searchMode = searchMode.getOrElse(SearchMode.Normal)
        )
        searchItemStats(backend, dsl)(settings, fixQuery, itemQuery)

      case req @ POST -> Root / "search" =>
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
            searchMode = userQuery.searchMode.getOrElse(SearchMode.Normal)
          )
          fixQuery = Query.Fix(user.account, None, None)
          resp <- searchItems(backend, dsl)(settings, fixQuery, itemQuery)
        } yield resp

      case req @ POST -> Root / "searchStats" =>
        for {
          userQuery <- req.as[ItemQuery]
          itemQuery = ItemQueryString(userQuery.query)
          fixQuery = Query.Fix(user.account, None, None)
          settings = OSimpleSearch.StatsSettings(
            useFTS = cfg.fullTextSearch.enabled,
            searchMode = userQuery.searchMode.getOrElse(SearchMode.Normal)
          )
          resp <- searchItemStats(backend, dsl)(settings, fixQuery, itemQuery)
        } yield resp

      case req @ POST -> Root / "searchIndex" =>
        for {
          mask <- req.as[ItemQuery]
          resp <- mask.query match {
            case q if q.length > 1 =>
              val ftsIn = OFulltext.FtsInput(q)
              for {
                items <- backend.fulltext.findIndexOnly(cfg.maxNoteLength)(
                  ftsIn,
                  user.account,
                  Batch(
                    mask.offset.getOrElse(0),
                    mask.limit.getOrElse(cfg.maxItemPageSize)
                  ).restrictLimitTo(cfg.maxItemPageSize)
                )
                ok <- Ok(Conversions.mkItemListWithTagsFtsPlain(items))
              } yield ok

            case _ =>
              BadRequest(BasicResult(false, "Query string too short"))
          }
        } yield resp

      case GET -> Root / Ident(id) =>
        for {
          item <- backend.itemSearch.findItem(id, user.account.collective)
          result = item.map(Conversions.mkItemDetail)
          resp <-
            result
              .map(r => Ok(r))
              .getOrElse(NotFound(BasicResult(false, "Not found.")))
        } yield resp

      case POST -> Root / Ident(id) / "confirm" =>
        for {
          res <- backend.item.setState(id, ItemState.Confirmed, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Item data confirmed"))
        } yield resp

      case POST -> Root / Ident(id) / "unconfirm" =>
        for {
          res <- backend.item.setState(id, ItemState.Created, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Item back to created."))
        } yield resp

      case POST -> Root / Ident(id) / "restore" =>
        for {
          res <- backend.item.restore(NonEmptyList.of(id), user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Item restored."))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "tags" =>
        for {
          tags <- req.as[StringList].map(_.items)
          res <- backend.item.setTags(id, tags, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Tags updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "tags" =>
        for {
          data <- req.as[Tag]
          rtag <- Conversions.newTag(data, user.account.collective)
          res <- backend.item.addNewTag(id, rtag)
          resp <- Ok(Conversions.basicResult(res, "Tag added."))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "taglink" =>
        for {
          tags <- req.as[StringList]
          res <- backend.item.linkTags(id, tags.items, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Tags linked"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "tagtoggle" =>
        for {
          tags <- req.as[StringList]
          res <- backend.item.toggleTags(id, tags.items, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Tags linked"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "tagsremove" =>
        for {
          json <- req.as[StringList]
          res <- backend.item.removeTagsMultipleItems(
            NonEmptyList.of(id),
            json.items,
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Tags removed"))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "direction" =>
        for {
          dir <- req.as[DirectionValue]
          res <- backend.item.setDirection(
            NonEmptyList.of(id),
            dir.direction,
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Direction updated"))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "folder" =>
        for {
          idref <- req.as[OptionalId]
          res <- backend.item.setFolder(id, idref.id, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Folder updated"))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "corrOrg" =>
        for {
          idref <- req.as[OptionalId]
          res <- backend.item.setCorrOrg(
            NonEmptyList.of(id),
            idref.id,
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Correspondent organization updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "corrOrg" =>
        for {
          data <- req.as[Organization]
          org <- Conversions.newOrg(data, user.account.collective)
          res <- backend.item.addCorrOrg(id, org)
          resp <- Ok(Conversions.basicResult(res, "Correspondent organization updated"))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "corrPerson" =>
        for {
          idref <- req.as[OptionalId]
          res <- backend.item.setCorrPerson(
            NonEmptyList.of(id),
            idref.id,
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Correspondent person updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "corrPerson" =>
        for {
          data <- req.as[Person]
          pers <- Conversions.newPerson(data, user.account.collective)
          res <- backend.item.addCorrPerson(id, pers)
          resp <- Ok(Conversions.basicResult(res, "Correspondent person updated"))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "concPerson" =>
        for {
          idref <- req.as[OptionalId]
          res <- backend.item.setConcPerson(
            NonEmptyList.of(id),
            idref.id,
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Concerned person updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "concPerson" =>
        for {
          data <- req.as[Person]
          pers <- Conversions.newPerson(data, user.account.collective)
          res <- backend.item.addConcPerson(id, pers)
          resp <- Ok(Conversions.basicResult(res, "Concerned person updated"))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "concEquipment" =>
        for {
          idref <- req.as[OptionalId]
          res <- backend.item.setConcEquip(
            NonEmptyList.of(id),
            idref.id,
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Concerned equipment updated"))
        } yield resp

      case req @ POST -> Root / Ident(id) / "concEquipment" =>
        for {
          data <- req.as[Equipment]
          equip <- Conversions.newEquipment(data, user.account.collective)
          res <- backend.item.addConcEquip(id, equip)
          resp <- Ok(Conversions.basicResult(res, "Concerned equipment updated"))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "notes" =>
        for {
          text <- req.as[OptionalText]
          res <- backend.item.setNotes(id, text.text.notEmpty, user.account.collective)
          resp <- Ok(Conversions.basicResult(res, "Notes updated"))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "name" =>
        for {
          text <- req.as[OptionalText]
          res <- backend.item.setName(
            id,
            text.text.notEmpty.getOrElse(""),
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Name updated"))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "duedate" =>
        for {
          date <- req.as[OptionalDate]
          _ <- logger.fdebug(s"Setting item due date to ${date.date}")
          res <- backend.item.setItemDueDate(
            NonEmptyList.of(id),
            date.date,
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Item due date updated"))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "date" =>
        for {
          date <- req.as[OptionalDate]
          _ <- logger.fdebug(s"Setting item date to ${date.date}")
          res <- backend.item.setItemDate(
            NonEmptyList.of(id),
            date.date,
            user.account.collective
          )
          resp <- Ok(Conversions.basicResult(res, "Item date updated"))
        } yield resp

      case GET -> Root / Ident(id) / "proposals" =>
        for {
          ml <- backend.item.getProposals(id, user.account.collective)
          ip = Conversions.mkItemProposals(ml)
          resp <- Ok(ip)
        } yield resp

      case req @ POST -> Root / Ident(id) / "attachment" / "movebefore" =>
        for {
          data <- req.as[MoveAttachment]
          _ <- logger.fdebug(s"Move item (${id.id}) attachment $data")
          res <- backend.item.moveAttachmentBefore(id, data.source, data.target)
          resp <- Ok(Conversions.basicResult(res, "Attachment moved."))
        } yield resp

      case req @ GET -> Root / Ident(id) / "preview" :? QP.WithFallback(flag) =>
        def notFound =
          NotFound(BasicResult(false, "Not found"))
        for {
          preview <- backend.itemSearch.findItemPreview(id, user.account.collective)
          inm = req.headers.get[`If-None-Match`].flatMap(_.tags)
          matches = BinaryUtil.matchETag(preview.map(_.meta), inm)
          fallback = flag.getOrElse(false)
          resp <-
            preview
              .map { data =>
                if (matches) BinaryUtil.withResponseHeaders(dsl, NotModified())(data)
                else BinaryUtil.makeByteResp(dsl)(data).map(Responses.noCache)
              }
              .getOrElse(
                if (fallback) BinaryUtil.noPreview(req.some).getOrElseF(notFound)
                else notFound
              )
        } yield resp

      case HEAD -> Root / Ident(id) / "preview" =>
        for {
          preview <- backend.itemSearch.findItemPreview(id, user.account.collective)
          resp <-
            preview
              .map(data => BinaryUtil.withResponseHeaders(dsl, Ok())(data))
              .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case req @ POST -> Root / Ident(id) / "reprocess" =>
        for {
          data <- req.as[IdList]
          ids = data.ids.flatMap(s => Ident.fromString(s).toOption)
          _ <- logger.fdebug(s"Re-process item ${id.id}")
          res <- backend.item.reprocess(id, ids, user.account, true)
          resp <- Ok(Conversions.basicResult(res, "Re-process task submitted."))
        } yield resp

      case req @ PUT -> Root / Ident(id) / "customfield" =>
        for {
          data <- req.as[CustomFieldValue]
          res <- backend.customFields.setValue(
            id,
            SetValue(data.field, data.value, user.account.collective)
          )
          resp <- Ok(Conversions.basicResult(res))
        } yield resp

      case DELETE -> Root / Ident(id) / "customfield" / Ident(fieldId) =>
        for {
          res <- backend.customFields.deleteValue(
            RemoveValue(fieldId, NonEmptyList.of(id), user.account.collective)
          )
          resp <- Ok(Conversions.basicResult(res, "Custom field value removed."))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          n <- backend.item.setDeletedState(NonEmptyList.of(id), user.account.collective)
          res = BasicResult(n > 0, if (n > 0) "Item deleted" else "Item deletion failed.")
          resp <- Ok(res)
        } yield resp
    }
  }

  def searchItems[F[_]: Sync](
      backend: BackendApp[F],
      dsl: Http4sDsl[F]
  )(
      settings: OSimpleSearch.Settings,
      fixQuery: Query.Fix,
      itemQuery: ItemQueryString
  ): F[Response[F]] = {
    import dsl._

    def convertFts(res: OSimpleSearch.Items.FtsItems): ItemLightList =
      if (res.indexOnly) Conversions.mkItemListFtsPlain(res.items)
      else Conversions.mkItemListFts(res.items)

    def convertFtsFull(res: OSimpleSearch.Items.FtsItemsFull): ItemLightList =
      if (res.indexOnly) Conversions.mkItemListWithTagsFtsPlain(res.items)
      else Conversions.mkItemListWithTagsFts(res.items)

    backend.simpleSearch
      .searchByString(settings)(fixQuery, itemQuery)
      .flatMap {
        case StringSearchResult.Success(items) =>
          Ok(
            items.fold(
              convertFts,
              convertFtsFull,
              Conversions.mkItemList,
              Conversions.mkItemListWithTags
            )
          )
        case StringSearchResult.FulltextMismatch(TooMany) =>
          BadRequest(BasicResult(false, "Only one fulltext search term is allowed."))
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

  def searchItemStats[F[_]: Sync](
      backend: BackendApp[F],
      dsl: Http4sDsl[F]
  )(
      settings: OSimpleSearch.StatsSettings,
      fixQuery: Query.Fix,
      itemQuery: ItemQueryString
  ): F[Response[F]] = {
    import dsl._

    backend.simpleSearch
      .searchSummaryByString(settings)(fixQuery, itemQuery)
      .flatMap {
        case StringSearchResult.Success(summary) =>
          Ok(Conversions.mkSearchStats(summary))
        case StringSearchResult.FulltextMismatch(TooMany) =>
          BadRequest(BasicResult(false, "Only one fulltext search term is allowed."))
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

  implicit final class OptionString(opt: Option[String]) {
    def notEmpty: Option[String] =
      opt.map(_.trim).filter(_.nonEmpty)
  }
}
