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
import docspell.common._
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s.BinaryUtil
import docspell.restserver.http4s.ClientRequestInfo
import docspell.restserver.http4s.Responses
import docspell.restserver.http4s.{QueryParam => QP}
import docspell.scheduler.usertask.UserTaskScope

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._

object ItemRoutes {
  def apply[F[_]: Async](
      cfg: Config,
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val logger = docspell.logging.getLogger[F]
    val searchPart = ItemSearchPart[F](backend.search, cfg, user)
    val dsl = new Http4sDsl[F] {}
    import dsl._

    searchPart.routes <+>
      HttpRoutes.of {
        case GET -> Root / Ident(id) =>
          for {
            item <- backend.itemSearch.findItem(id, user.account.collectiveId)
            result = item.map(Conversions.mkItemDetail)
            resp <-
              result
                .map(r => Ok(r))
                .getOrElse(NotFound(BasicResult(success = false, "Not found.")))
          } yield resp

        case POST -> Root / Ident(id) / "confirm" =>
          for {
            res <- backend.item.setState(
              id,
              ItemState.Confirmed,
              user.account.collectiveId
            )
            resp <- Ok(Conversions.basicResult(res, "Item data confirmed"))
          } yield resp

        case POST -> Root / Ident(id) / "unconfirm" =>
          for {
            res <- backend.item.setState(id, ItemState.Created, user.account.collectiveId)
            resp <- Ok(Conversions.basicResult(res, "Item back to created."))
          } yield resp

        case POST -> Root / Ident(id) / "restore" =>
          for {
            res <- backend.item.restore(NonEmptyList.of(id), user.account.collectiveId)
            resp <- Ok(Conversions.basicResult(res, "Item restored."))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "tags" =>
          for {
            tags <- req.as[StringList].map(_.items)
            res <- backend.item.setTags(id, tags, user.account.collectiveId)
            baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
            _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
            resp <- Ok(Conversions.basicResult(res.value, "Tags updated"))
          } yield resp

        case req @ POST -> Root / Ident(id) / "tags" =>
          for {
            data <- req.as[Tag]
            rtag <- Conversions.newTag(data, user.account.collectiveId)
            res <- backend.item.addNewTag(user.account.collectiveId, id, rtag)
            baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
            _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
            resp <- Ok(Conversions.basicResult(res.value, "Tag added."))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "taglink" =>
          for {
            tags <- req.as[StringList]
            res <- backend.item.linkTags(id, tags.items, user.account.collectiveId)
            baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
            _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
            resp <- Ok(Conversions.basicResult(res.value, "Tags linked"))
          } yield resp

        case req @ POST -> Root / Ident(id) / "tagtoggle" =>
          for {
            tags <- req.as[StringList]
            res <- backend.item.toggleTags(id, tags.items, user.account.collectiveId)
            baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
            _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
            resp <- Ok(Conversions.basicResult(res.value, "Tags linked"))
          } yield resp

        case req @ POST -> Root / Ident(id) / "tagsremove" =>
          for {
            json <- req.as[StringList]
            res <- backend.item.removeTagsMultipleItems(
              NonEmptyList.of(id),
              json.items,
              user.account.collectiveId
            )
            baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
            _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
            resp <- Ok(Conversions.basicResult(res.value, "Tags removed"))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "direction" =>
          for {
            dir <- req.as[DirectionValue]
            res <- backend.item.setDirection(
              NonEmptyList.of(id),
              dir.direction,
              user.account.collectiveId
            )
            resp <- Ok(Conversions.basicResult(res, "Direction updated"))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "folder" =>
          for {
            idref <- req.as[OptionalId]
            res <- backend.item.setFolder(
              id,
              idref.id.map(_.id),
              user.account.collectiveId
            )
            resp <- Ok(Conversions.basicResult(res, "Folder updated"))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "corrOrg" =>
          for {
            idref <- req.as[OptionalId]
            res <- backend.item.setCorrOrg(
              NonEmptyList.of(id),
              idref.id,
              user.account.collectiveId
            )
            resp <- Ok(Conversions.basicResult(res, "Correspondent organization updated"))
          } yield resp

        case req @ POST -> Root / Ident(id) / "corrOrg" =>
          for {
            data <- req.as[Organization]
            org <- Conversions.newOrg(data, user.account.collectiveId)
            res <- backend.item.addCorrOrg(id, org)
            resp <- Ok(Conversions.basicResult(res, "Correspondent organization updated"))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "corrPerson" =>
          for {
            idref <- req.as[OptionalId]
            res <- backend.item.setCorrPerson(
              NonEmptyList.of(id),
              idref.id,
              user.account.collectiveId
            )
            resp <- Ok(Conversions.basicResult(res, "Correspondent person updated"))
          } yield resp

        case req @ POST -> Root / Ident(id) / "corrPerson" =>
          for {
            data <- req.as[Person]
            pers <- Conversions.newPerson(data, user.account.collectiveId)
            res <- backend.item.addCorrPerson(id, pers)
            resp <- Ok(Conversions.basicResult(res, "Correspondent person updated"))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "concPerson" =>
          for {
            idref <- req.as[OptionalId]
            res <- backend.item.setConcPerson(
              NonEmptyList.of(id),
              idref.id,
              user.account.collectiveId
            )
            resp <- Ok(Conversions.basicResult(res, "Concerned person updated"))
          } yield resp

        case req @ POST -> Root / Ident(id) / "concPerson" =>
          for {
            data <- req.as[Person]
            pers <- Conversions.newPerson(data, user.account.collectiveId)
            res <- backend.item.addConcPerson(id, pers)
            resp <- Ok(Conversions.basicResult(res, "Concerned person updated"))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "concEquipment" =>
          for {
            idref <- req.as[OptionalId]
            res <- backend.item.setConcEquip(
              NonEmptyList.of(id),
              idref.id,
              user.account.collectiveId
            )
            resp <- Ok(Conversions.basicResult(res, "Concerned equipment updated"))
          } yield resp

        case req @ POST -> Root / Ident(id) / "concEquipment" =>
          for {
            data <- req.as[Equipment]
            equip <- Conversions.newEquipment(data, user.account.collectiveId)
            res <- backend.item.addConcEquip(id, equip)
            resp <- Ok(Conversions.basicResult(res, "Concerned equipment updated"))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "notes" =>
          for {
            text <- req.as[OptionalText]
            res <- backend.item.setNotes(
              id,
              text.text.notEmpty,
              user.account.collectiveId
            )
            resp <- Ok(Conversions.basicResult(res, "Notes updated"))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "name" =>
          for {
            text <- req.as[OptionalText]
            res <- backend.item.setName(
              id,
              text.text.notEmpty.getOrElse(""),
              user.account.collectiveId
            )
            resp <- Ok(Conversions.basicResult(res, "Name updated"))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "duedate" =>
          for {
            date <- req.as[OptionalDate]
            _ <- logger.debug(s"Setting item due date to ${date.date}")
            res <- backend.item.setItemDueDate(
              NonEmptyList.of(id),
              date.date,
              user.account.collectiveId
            )
            resp <- Ok(Conversions.basicResult(res, "Item due date updated"))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "date" =>
          for {
            date <- req.as[OptionalDate]
            _ <- logger.debug(s"Setting item date to ${date.date}")
            res <- backend.item.setItemDate(
              NonEmptyList.of(id),
              date.date,
              user.account.collectiveId
            )
            resp <- Ok(Conversions.basicResult(res, "Item date updated"))
          } yield resp

        case GET -> Root / Ident(id) / "proposals" =>
          for {
            ml <- backend.item.getProposals(id, user.account.collectiveId)
            ip = Conversions.mkItemProposals(ml)
            resp <- Ok(ip)
          } yield resp

        case req @ POST -> Root / Ident(id) / "attachment" / "movebefore" =>
          for {
            data <- req.as[MoveAttachment]
            _ <- logger.debug(s"Move item (${id.id}) attachment $data")
            res <- backend.item.moveAttachmentBefore(id, data.source, data.target)
            resp <- Ok(Conversions.basicResult(res, "Attachment moved."))
          } yield resp

        case req @ GET -> Root / Ident(id) / "preview" :? QP.WithFallback(flag) =>
          def notFound =
            NotFound(BasicResult(success = false, "Not found"))
          for {
            preview <- backend.itemSearch.findItemPreview(id, user.account.collectiveId)
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
            preview <- backend.itemSearch.findItemPreview(id, user.account.collectiveId)
            resp <-
              preview
                .map(data => BinaryUtil.withResponseHeaders(dsl, Ok())(data))
                .getOrElse(NotFound(BasicResult(success = false, "Not found")))
          } yield resp

        case req @ POST -> Root / Ident(id) / "reprocess" =>
          for {
            data <- req.as[IdList]
            _ <- logger.debug(s"Re-process item ${id.id}")
            res <- backend.item.reprocess(
              user.account.collectiveId,
              id,
              data.ids,
              UserTaskScope(user.account)
            )
            resp <- Ok(Conversions.basicResult(res, "Re-process task submitted."))
          } yield resp

        case req @ PUT -> Root / Ident(id) / "customfield" =>
          for {
            data <- req.as[CustomFieldValue]
            res <- backend.customFields.setValue(
              id,
              SetValue(data.field, data.value, user.account.collectiveId)
            )
            baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
            _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
            resp <- Ok(Conversions.basicResult(res.value))
          } yield resp

        case req @ DELETE -> Root / Ident(id) / "customfield" / Ident(fieldId) =>
          for {
            res <- backend.customFields.deleteValue(
              RemoveValue(fieldId, NonEmptyList.of(id), user.account.collectiveId)
            )
            baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
            _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
            resp <- Ok(Conversions.basicResult(res.value, "Custom field value removed."))
          } yield resp

        case DELETE -> Root / Ident(id) =>
          for {
            n <- backend.item.setDeletedState(
              NonEmptyList.of(id),
              user.account.collectiveId
            )
            res = BasicResult(
              n > 0,
              if (n > 0) "Item deleted" else "Item deletion failed."
            )
            resp <- Ok(res)
          } yield resp
      }
  }

  implicit final class OptionString(opt: Option[String]) {
    def notEmpty: Option[String] =
      opt.map(_.trim).filter(_.nonEmpty)
  }
}
