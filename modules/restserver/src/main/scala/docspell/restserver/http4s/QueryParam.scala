/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.http4s

import docspell.backend.ops.OCustomFields.CustomFieldOrder
import docspell.backend.ops.OEquipment.EquipmentOrder
import docspell.backend.ops.OFolder.FolderOrder
import docspell.backend.ops.OOrganization.{OrganizationOrder, PersonOrder}
import docspell.backend.ops.OTag.TagOrder
import docspell.common.ContactKind
import docspell.common.SearchMode

import org.http4s.ParseFailure
import org.http4s.QueryParamDecoder
import org.http4s.dsl.impl.OptionalQueryParamDecoderMatcher

object QueryParam {
  case class QueryString(q: String)

  implicit val contactKindDecoder: QueryParamDecoder[ContactKind] =
    QueryParamDecoder[String].emap(str =>
      ContactKind.fromString(str).left.map(s => ParseFailure(str, s))
    )

  implicit val queryStringDecoder: QueryParamDecoder[QueryString] =
    QueryParamDecoder[String].map(s => QueryString(s.trim.toLowerCase))

  implicit val searchModeDecoder: QueryParamDecoder[SearchMode] =
    QueryParamDecoder[String].emap(str =>
      SearchMode.fromString(str).left.map(s => ParseFailure(str, s))
    )

  implicit val tagOrderDecoder: QueryParamDecoder[TagOrder] =
    QueryParamDecoder[String].emap(str =>
      TagOrder.parse(str).left.map(s => ParseFailure(str, s))
    )

  implicit val euqipOrderDecoder: QueryParamDecoder[EquipmentOrder] =
    QueryParamDecoder[String].emap(str =>
      EquipmentOrder.parse(str).left.map(s => ParseFailure(str, s))
    )

  implicit val orgOrderDecoder: QueryParamDecoder[OrganizationOrder] =
    QueryParamDecoder[String].emap(str =>
      OrganizationOrder.parse(str).left.map(s => ParseFailure(str, s))
    )

  implicit val personOrderDecoder: QueryParamDecoder[PersonOrder] =
    QueryParamDecoder[String].emap(str =>
      PersonOrder.parse(str).left.map(s => ParseFailure(str, s))
    )

  implicit val folderOrderDecoder: QueryParamDecoder[FolderOrder] =
    QueryParamDecoder[String].emap(str =>
      FolderOrder.parse(str).left.map(s => ParseFailure(str, s))
    )

  implicit val customFieldOrderDecoder: QueryParamDecoder[CustomFieldOrder] =
    QueryParamDecoder[String].emap(str =>
      CustomFieldOrder.parse(str).left.map(s => ParseFailure(str, s))
    )

  object FullOpt extends OptionalQueryParamDecoderMatcher[Boolean]("full")

  object OwningOpt extends OptionalQueryParamDecoderMatcher[Boolean]("owning")

  object ContactKindOpt extends OptionalQueryParamDecoderMatcher[ContactKind]("kind")

  object QueryOpt extends OptionalQueryParamDecoderMatcher[QueryString]("q")

  object Query       extends OptionalQueryParamDecoderMatcher[String]("q")
  object Limit       extends OptionalQueryParamDecoderMatcher[Int]("limit")
  object Offset      extends OptionalQueryParamDecoderMatcher[Int]("offset")
  object WithDetails extends OptionalQueryParamDecoderMatcher[Boolean]("withDetails")
  object SearchKind  extends OptionalQueryParamDecoderMatcher[SearchMode]("searchMode")
  object TagSort     extends OptionalQueryParamDecoderMatcher[TagOrder]("sort")
  object EquipSort   extends OptionalQueryParamDecoderMatcher[EquipmentOrder]("sort")
  object OrgSort     extends OptionalQueryParamDecoderMatcher[OrganizationOrder]("sort")
  object PersonSort  extends OptionalQueryParamDecoderMatcher[PersonOrder]("sort")
  object FolderSort  extends OptionalQueryParamDecoderMatcher[FolderOrder]("sort")
  object FieldSort   extends OptionalQueryParamDecoderMatcher[CustomFieldOrder]("sort")

  object WithFallback extends OptionalQueryParamDecoderMatcher[Boolean]("withFallback")
}
