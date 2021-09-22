/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftssolr

import docspell.ftsclient.FtsQuery

import io.circe._
import io.circe.generic.semiauto._

final case class QueryData(
    query: String,
    filter: String,
    limit: Int,
    offset: Int,
    fields: List[Field],
    params: Map[String, String]
) {

  def nextPage: QueryData =
    copy(offset = offset + limit)

  def withHighLight(fields: List[Field], pre: String, post: String): QueryData =
    copy(params =
      params ++ Map(
        "hl" -> "on",
        "hl.requireFieldMatch" -> "true",
        "hl.fl" -> fields.map(_.name).mkString(","),
        "hl.simple.pre" -> pre,
        "hl.simple.post" -> post
      )
    )
}

object QueryData {

  implicit val jsonEncoder: Encoder[QueryData] =
    deriveEncoder[QueryData]

  def apply(
      cfg: SolrConfig,
      search: List[Field],
      fields: List[Field],
      fq: FtsQuery
  ): QueryData = {
    val q = sanitize(fq.q)
    val extQ = search.map(f => s"${f.name}:($q)").mkString(" OR ")
    val items = fq.items.map(_.id).mkString(" ")
    val folders = fq.folders.map(_.id).mkString(" ")
    val filterQ = List(
      s"""${Field.collectiveId.name}:"${fq.collective.id}"""",
      fq.items match {
        case s if s.isEmpty =>
          ""
        case _ =>
          s"""${Field.itemId.name}:($items)"""
      },
      fq.folders match {
        case s if s.isEmpty =>
          ""
        case _ =>
          s"""${Field.folderId.name}:($folders) OR (*:* NOT ${Field.folderId.name}:*)"""
      }
    ).filterNot(_.isEmpty).map(t => s"($t)").mkString(" AND ")

    QueryData(
      extQ,
      filterQ,
      fq.limit,
      fq.offset,
      fields,
      Map("defType" -> cfg.defType, "q.op" -> cfg.qOp)
    ).withHighLight(
      search,
      fq.highlight.pre,
      fq.highlight.post
    )
  }

  private def sanitize(q: String): String =
    q.replaceAll("[\\(,\\)]+", " ")
}
