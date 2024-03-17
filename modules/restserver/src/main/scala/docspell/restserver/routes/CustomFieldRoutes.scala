/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OCustomFields
import docspell.backend.ops.OCustomFields.{CustomFieldData, CustomFieldOrder}
import docspell.common._
import docspell.restapi.model._
import docspell.restserver.conv.Conversions
import docspell.restserver.http4s._
import docspell.store.AddResult
import docspell.store.UpdateResult
import docspell.store.records.RCustomField

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object CustomFieldRoutes {

  def apply[F[_]: Async](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] with ResponseGenerator[F] {}
    import dsl._

    HttpRoutes.of {
      case GET -> Root :? QueryParam.QueryOpt(param) +& QueryParam.FieldSort(sort) =>
        val order = sort.getOrElse(CustomFieldOrder.NameAsc)
        for {
          fs <- backend.customFields.findAll(
            user.account.collectiveId,
            param.map(_.q),
            order
          )
          res <- Ok(CustomFieldList(fs.map(convertField).toList))
        } yield res

      case req @ POST -> Root =>
        for {
          data <- req.as[NewCustomField]
          res <- backend.customFields.create(convertNewField(user, data))
          resp <- Ok(convertResult(res))
        } yield resp

      case GET -> Root / Ident(id) =>
        (for {
          field <- OptionT(backend.customFields.findById(user.account.collectiveId, id))
          res <- OptionT.liftF(Ok(convertField(field)))
        } yield res).getOrElseF(NotFound(BasicResult(success = false, "Not found")))

      case req @ PUT -> Root / Ident(id) =>
        for {
          data <- req.as[NewCustomField]
          res <- backend.customFields.change(convertChangeField(id, user, data))
          resp <- Ok(convertResult(res))
        } yield resp

      case DELETE -> Root / Ident(id) =>
        for {
          res <- backend.customFields.delete(user.account.collectiveId, id)
          resp <- Ok(convertResult(res))
        } yield resp
    }
  }

  private def convertResult(r: AddResult): BasicResult =
    Conversions.basicResult(r, "New field created.")

  private def convertResult(r: UpdateResult): BasicResult =
    Conversions.basicResult(r, "Field updated.")

  private def convertChangeField(
      id: Ident,
      user: AuthToken,
      in: NewCustomField
  ): RCustomField =
    RCustomField(
      id,
      in.name,
      in.label,
      user.account.collectiveId,
      in.ftype,
      Timestamp.Epoch
    )

  private def convertNewField(
      user: AuthToken,
      in: NewCustomField
  ): OCustomFields.NewCustomField =
    OCustomFields.NewCustomField(
      in.name,
      in.label,
      in.ftype,
      user.account.collectiveId
    )

  private def convertField(f: CustomFieldData): CustomField =
    CustomField(
      f.field.id,
      f.field.name,
      f.field.label,
      f.field.ftype,
      f.usageCount,
      f.field.created
    )
}
