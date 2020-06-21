package docspell.ftssolr

import cats.effect._
import org.http4s._
import org.http4s.client.Client
import org.http4s.circe._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.client.dsl.Http4sClientDsl
import _root_.io.circe.syntax._
import org.log4s.getLogger

import docspell.ftsclient._
import JsonCodec._

trait SolrQuery[F[_]] {

  def query(q: QueryData): F[FtsResult]

  def query(q: FtsQuery): F[FtsResult] = {
    val fq = QueryData(
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
        Field.discriminator
      ),
      q
    )
    query(fq)
  }
}

object SolrQuery {
  private[this] val logger = getLogger

  def apply[F[_]: ConcurrentEffect](cfg: SolrConfig, client: Client[F]): SolrQuery[F] = {
    val dsl = new Http4sClientDsl[F] {}
    import dsl._

    new SolrQuery[F] {
      val url = Uri.unsafeFromString(cfg.url.asString) / "query"

      def query(q: QueryData): F[FtsResult] = {
        val req = Method.POST(q.asJson, url)
        logger.debug(s"Running query: $req")
        client.expect[FtsResult](req)
      }

    }
  }
}
