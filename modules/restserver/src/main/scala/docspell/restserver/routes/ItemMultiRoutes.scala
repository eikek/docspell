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
import docspell.backend.ops.OCustomFields.{RemoveValue, SetValue}
import docspell.common._
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.{Conversions, MultiIdSupport, NonEmptyListSupport}
import docspell.restserver.http4s.ClientRequestInfo
import docspell.scheduler.usertask.UserTaskScope

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object ItemMultiRoutes extends NonEmptyListSupport with MultiIdSupport {

  def apply[F[_]: Async](
      cfg: Config,
      backend: BackendApp[F],
      user: AuthToken
  ): HttpRoutes[F] = {
    val logger = docspell.logging.getLogger[F]
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of {
      case req @ PUT -> Root / "confirm" =>
        for {
          json <- req.as[IdList]
          data <- requireNonEmpty(json.ids)
          res <- backend.item.setStates(
            data,
            ItemState.Confirmed,
            user.account.collectiveId
          )
          resp <- Ok(Conversions.basicResult(res, "Item data confirmed"))
        } yield resp

      case req @ PUT -> Root / "unconfirm" =>
        for {
          json <- req.as[IdList]
          data <- requireNonEmpty(json.ids)
          res <- backend.item.setStates(
            data,
            ItemState.Created,
            user.account.collectiveId
          )
          resp <- Ok(Conversions.basicResult(res, "Item back to created."))
        } yield resp

      case req @ PUT -> Root / "tags" =>
        for {
          json <- req.as[ItemsAndRefs]
          items <- requireNonEmpty(json.items)
          res <- backend.item.setTagsMultipleItems(
            items,
            json.refs,
            user.account.collectiveId
          )
          baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
          _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
          resp <- Ok(Conversions.basicResult(res.value, "Tags updated"))
        } yield resp

      case req @ POST -> Root / "tags" =>
        for {
          json <- req.as[ItemsAndRefs]
          items <- requireNonEmpty(json.items)
          res <- backend.item.linkTagsMultipleItems(
            items,
            json.refs,
            user.account.collectiveId
          )
          baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
          _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
          resp <- Ok(Conversions.basicResult(res.value, "Tags added."))
        } yield resp

      case req @ POST -> Root / "tagsremove" =>
        for {
          json <- req.as[ItemsAndRefs]
          items <- requireNonEmpty(json.items)
          res <- backend.item.removeTagsMultipleItems(
            items,
            json.refs,
            user.account.collectiveId
          )
          baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
          _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
          resp <- Ok(Conversions.basicResult(res.value, "Tags removed"))
        } yield resp

      case req @ PUT -> Root / "name" =>
        for {
          json <- req.as[ItemsAndName]
          items <- requireNonEmpty(json.items)
          res <- backend.item.setNameMultiple(
            items,
            json.name.notEmpty.getOrElse(""),
            user.account.collectiveId
          )
          resp <- Ok(Conversions.basicResult(res, "Name updated"))
        } yield resp

      case req @ PUT -> Root / "folder" =>
        for {
          json <- req.as[ItemsAndRef]
          items <- requireNonEmpty(json.items)
          res <- backend.item.setFolderMultiple(
            items,
            json.ref.map(_.id),
            user.account.collectiveId
          )
          resp <- Ok(Conversions.basicResult(res, "Folder updated"))
        } yield resp

      case req @ PUT -> Root / "direction" =>
        for {
          json <- req.as[ItemsAndDirection]
          items <- requireNonEmpty(json.items)
          res <- backend.item.setDirection(
            items,
            json.direction,
            user.account.collectiveId
          )
          resp <- Ok(Conversions.basicResult(res, "Direction updated"))
        } yield resp

      case req @ PUT -> Root / "date" =>
        for {
          json <- req.as[ItemsAndDate]
          items <- requireNonEmpty(json.items)
          res <- backend.item.setItemDate(items, json.date, user.account.collectiveId)
          resp <- Ok(Conversions.basicResult(res, "Item date updated"))
        } yield resp

      case req @ PUT -> Root / "duedate" =>
        for {
          json <- req.as[ItemsAndDate]
          items <- requireNonEmpty(json.items)
          res <- backend.item.setItemDueDate(items, json.date, user.account.collectiveId)
          resp <- Ok(Conversions.basicResult(res, "Item due date updated"))
        } yield resp

      case req @ PUT -> Root / "corrOrg" =>
        for {
          json <- req.as[ItemsAndRef]
          items <- requireNonEmpty(json.items)
          res <- backend.item.setCorrOrg(items, json.ref, user.account.collectiveId)
          resp <- Ok(Conversions.basicResult(res, "Correspondent organization updated"))
        } yield resp

      case req @ PUT -> Root / "corrPerson" =>
        for {
          json <- req.as[ItemsAndRef]
          items <- requireNonEmpty(json.items)
          res <- backend.item.setCorrPerson(items, json.ref, user.account.collectiveId)
          resp <- Ok(Conversions.basicResult(res, "Correspondent person updated"))
        } yield resp

      case req @ PUT -> Root / "concPerson" =>
        for {
          json <- req.as[ItemsAndRef]
          items <- requireNonEmpty(json.items)
          res <- backend.item.setConcPerson(items, json.ref, user.account.collectiveId)
          resp <- Ok(Conversions.basicResult(res, "Concerned person updated"))
        } yield resp

      case req @ PUT -> Root / "concEquipment" =>
        for {
          json <- req.as[ItemsAndRef]
          items <- requireNonEmpty(json.items)
          res <- backend.item.setConcEquip(items, json.ref, user.account.collectiveId)
          resp <- Ok(Conversions.basicResult(res, "Concerned equipment updated"))
        } yield resp

      case req @ POST -> Root / "reprocess" =>
        for {
          json <- req.as[IdList]
          items <- requireNonEmpty(json.ids)
          res <- backend.item.reprocessAll(
            user.account.collectiveId,
            items,
            UserTaskScope(user.account)
          )
          resp <- Ok(Conversions.basicResult(res, "Re-process task(s) submitted."))
        } yield resp

      case req @ POST -> Root / "deleteAll" =>
        for {
          json <- req.as[IdList]
          items <- requireNonEmpty(json.ids)
          n <- backend.item.setDeletedState(items, user.account.collectiveId)
          res = BasicResult(
            n > 0,
            if (n > 0) "Item(s) deleted" else "Item deletion failed."
          )
          resp <- Ok(res)
        } yield resp

      case req @ POST -> Root / "restoreAll" =>
        for {
          json <- req.as[IdList]
          items <- requireNonEmpty(json.ids)
          res <- backend.item.restore(items, user.account.collectiveId)
          resp <- Ok(Conversions.basicResult(res, "Item(s) deleted"))
        } yield resp

      case req @ PUT -> Root / "customfield" =>
        for {
          json <- req.as[ItemsAndFieldValue]
          items <- requireNonEmpty(json.items)
          res <- backend.customFields.setValueMultiple(
            items,
            SetValue(json.field.field, json.field.value, user.account.collectiveId)
          )
          baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
          _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
          resp <- Ok(Conversions.basicResult(res.value))
        } yield resp

      case req @ POST -> Root / "customfieldremove" =>
        for {
          json <- req.as[ItemsAndName]
          items <- requireNonEmpty(json.items)
          field <- readId[F](json.name)
          res <- backend.customFields.deleteValue(
            RemoveValue(field, items, user.account.collectiveId)
          )
          baseUrl = ClientRequestInfo.getBaseUrl(cfg, req)
          _ <- backend.notification.offerEvents(res.event(user.account, baseUrl.some))
          resp <- Ok(Conversions.basicResult(res.value, "Custom fields removed."))
        } yield resp

      case req @ POST -> Root / "merge" =>
        for {
          json <- req.as[IdList]
          items <- requireNonEmpty(json.ids)
          res <- backend.item.merge(logger, items, user.account.collectiveId)
          resp <- Ok(Conversions.basicResult(res, "Items merged"))
        } yield resp
    }
  }

  implicit final class OptionString(opt: Option[String]) {
    def notEmpty: Option[String] =
      opt.map(_.trim).filter(_.nonEmpty)
  }
  implicit final class StringOps(str: String) {
    def notEmpty: Option[String] =
      Option(str).notEmpty
  }
}
