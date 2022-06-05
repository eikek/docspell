/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops.search

import docspell.query.{FulltextExtract, ParseFailure}
import docspell.store.queries.Query

sealed trait QueryParseResult {
  def cast: QueryParseResult = this

  def get: Option[(Query, Option[String])]
  def isSuccess: Boolean = get.isDefined
  def isFailure: Boolean = !isSuccess

  def map(f: QueryParseResult.Success => QueryParseResult): QueryParseResult
}

object QueryParseResult {

  final case class Success(q: Query, ftq: Option[String]) extends QueryParseResult {

    /** Drop the fulltext search query if disabled. */
    def withFtsEnabled(enabled: Boolean) =
      if (enabled || ftq.isEmpty) this else copy(ftq = None)

    def map(f: QueryParseResult.Success => QueryParseResult): QueryParseResult =
      f(this)

    val get = Some(q -> ftq)
  }

  final case class ParseFailed(error: ParseFailure) extends QueryParseResult {
    val get = None
    def map(f: QueryParseResult.Success => QueryParseResult): QueryParseResult =
      this
  }

  final case class FulltextMismatch(error: FulltextExtract.FailureResult)
      extends QueryParseResult {
    val get = None
    def map(f: QueryParseResult.Success => QueryParseResult): QueryParseResult =
      this
  }
}
