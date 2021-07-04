/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.ftssolr

import cats.effect._

import docspell.ftsclient._
import docspell.ftssolr.JsonCodec._

import _root_.io.circe.syntax._
import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe._
import org.http4s.client.Client
import org.http4s.client.dsl.Http4sClientDsl

trait SolrQuery[F[_]] {

  def query(q: QueryData): F[FtsResult]

  def query(q: FtsQuery): F[FtsResult]

  def findVersionDoc(id: String): F[Option[VersionDoc]]
}

object SolrQuery {
  def apply[F[_]: Async](cfg: SolrConfig, client: Client[F]): SolrQuery[F] = {
    val dsl = new Http4sClientDsl[F] {}
    import dsl._

    new SolrQuery[F] {
      val url = Uri.unsafeFromString(cfg.url.asString) / "query"

      def query(q: QueryData): F[FtsResult] = {
        val req = Method.POST(q.asJson, url)
        client.expect[FtsResult](req)
      }

      def query(q: FtsQuery): F[FtsResult] = {
        val fq = QueryData(
          cfg,
          List(
            Field.content,
            Field.itemName,
            Field.itemNotes,
            Field.attachmentName
          ) ++ Field.contentLangFields,
          List(
            Field.id,
            Field.itemId,
            Field.collectiveId,
            Field("score"),
            Field.attachmentId,
            Field.attachmentName,
            Field.discriminator
          ),
          q
        )
        query(fq)
      }

      def findVersionDoc(id: String): F[Option[VersionDoc]] = {
        val fields = List(
          Field.id,
          Field("current_version_i")
        )
        val query = QueryData(s"id:$id", "", 1, 0, fields, Map.empty)
        val req   = Method.POST(query.asJson, url)
        client.expect[Option[VersionDoc]](req)
      }
    }
  }
}
