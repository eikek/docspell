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
}

object SolrQuery {
  def apply[F[_]: ConcurrentEffect](cfg: SolrConfig, client: Client[F]): SolrQuery[F] = {
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
            Field.content_de,
            Field.content_en,
            Field.itemName,
            Field.itemNotes,
            Field.attachmentName
          ),
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
    }
  }
}
