/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.restserver.http4s

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

  object FullOpt extends OptionalQueryParamDecoderMatcher[Boolean]("full")

  object OwningOpt extends OptionalQueryParamDecoderMatcher[Boolean]("owning")

  object ContactKindOpt extends OptionalQueryParamDecoderMatcher[ContactKind]("kind")

  object QueryOpt extends OptionalQueryParamDecoderMatcher[QueryString]("q")

  object Query       extends OptionalQueryParamDecoderMatcher[String]("q")
  object Limit       extends OptionalQueryParamDecoderMatcher[Int]("limit")
  object Offset      extends OptionalQueryParamDecoderMatcher[Int]("offset")
  object WithDetails extends OptionalQueryParamDecoderMatcher[Boolean]("withDetails")
  object SearchKind  extends OptionalQueryParamDecoderMatcher[SearchMode]("searchMode")

  object WithFallback extends OptionalQueryParamDecoderMatcher[Boolean]("withFallback")
}
