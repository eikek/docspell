/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.{NonEmptyList, OptionT}
import cats.effect._
import cats.implicits._

import docspell.backend.ops.OItemLink
import docspell.backend.ops.OItemLink.LinkResult
import docspell.common._
import docspell.joexapi.model.BasicResult
import docspell.restapi.model.{ItemLightGroup, ItemLinkData}
import docspell.restserver.conv.Conversions
import docspell.store.qb.Batch

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityCodec._
import org.http4s.dsl.Http4sDsl

class ItemLinkRoutes[F[_]: Async](account: AccountInfo, backend: OItemLink[F])
    extends Http4sDsl[F] {
  def get: HttpRoutes[F] =
    HttpRoutes.of {
      case GET -> Root / Ident(id) =>
        for {
          results <- backend.getRelated(account, id, Batch.all)
          conv = results.map(Conversions.mkItemLightWithTags)
          res = ItemLightGroup("related", conv.toList)
          resp <- Ok(res)
        } yield resp

      case DELETE -> Root / Ident(target) / Ident(id) =>
        for {
          _ <- backend.removeAll(account.collectiveId, target, NonEmptyList.of(id))
          resp <- Ok(BasicResult(success = true, "Related items removed"))
        } yield resp

      case req @ POST -> Root / "addAll" =>
        for {
          input <- req.as[ItemLinkData]
          related = NonEmptyList.fromList(input.related)
          res <- OptionT
            .fromOption[F](related)
            .semiflatMap(backend.addAll(account.collectiveId, input.item, _))
            .value
          resp <- Ok(convertResult(res))
        } yield resp

      case req @ POST -> Root / "removeAll" =>
        for {
          input <- req.as[ItemLinkData]
          related = NonEmptyList.fromList(input.related)
          _ <- related
            .map(backend.removeAll(account.collectiveId, input.item, _))
            .getOrElse(
              BadRequest(
                BasicResult(success = false, "List of related items must not be empty")
              )
            )
          resp <- Ok(BasicResult(success = true, "Related items removed"))
        } yield resp
    }

  private def convertResult(r: Option[LinkResult]): BasicResult =
    r match {
      case Some(LinkResult.Success) => BasicResult(success = true, "Related items added")
      case Some(LinkResult.LinkTargetItemError) =>
        BasicResult(success = false, "Items cannot be related to itself.")
      case None =>
        BasicResult(success = false, "List of related items must not be empty")
    }

}

object ItemLinkRoutes {

  def apply[F[_]: Async](account: AccountInfo, itemLink: OItemLink[F]): HttpRoutes[F] =
    new ItemLinkRoutes[F](account, itemLink).get
}
