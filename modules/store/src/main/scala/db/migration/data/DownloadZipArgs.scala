/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.data

import db.migration.data.DownloadZipArgs.DownloadRequest
import docspell.common._
import docspell.query.ItemQuery.Expr.ValidItemStates
import docspell.query.{ItemQuery, ItemQueryParser}
import docspell.store.queries.Query
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

/** @deprecated replaced with a version using `AccountInfo` */
final case class DownloadZipArgs(accountId: AccountId, req: DownloadRequest)

object DownloadZipArgs {
  val taskName: Ident = Ident.unsafe("download-query-zip")

  final case class DownloadRequest(
      query: ItemQuery,
      fileType: DownloadAllType,
      maxFiles: Int,
      maxSize: ByteSize
  ) {
    def toQuery(account: AccountInfo): Query =
      Query
        .all(account)
        .withFix(_.andQuery(ValidItemStates))
        .withCond(_ => Query.QueryExpr(query.expr))

    def itemQueryString =
      ItemQueryParser.asString(query.expr)
  }
  object DownloadRequest {
    implicit val itemQueryDecoder: Decoder[ItemQuery] =
      Decoder.decodeString.emap(str => ItemQueryParser.parse(str).left.map(_.render))

    implicit val itemQueryEncoder: Encoder[ItemQuery] =
      Encoder.encodeString.contramap(q =>
        q.raw.getOrElse(ItemQueryParser.unsafeAsString(q.expr))
      )

    implicit val jsonDecoder: Decoder[DownloadRequest] =
      deriveDecoder

    implicit val jsonEncoder: Encoder[DownloadRequest] =
      deriveEncoder
  }

  implicit val jsonEncoder: Encoder[DownloadZipArgs] =
    deriveEncoder
  implicit val jsonDecoder: Decoder[DownloadZipArgs] =
    deriveDecoder
}
