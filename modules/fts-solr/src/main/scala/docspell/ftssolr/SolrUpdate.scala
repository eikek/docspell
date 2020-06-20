package docspell.ftssolr

import cats.effect._
import org.http4s._
import cats.implicits._
import org.http4s.client.Client
import org.http4s.circe._
import org.http4s.client.dsl.Http4sClientDsl
import _root_.io.circe.syntax._
import org.log4s.getLogger

import docspell.ftsclient._
import JsonCodec._

trait SolrUpdate[F[_]] {

  def single(td: TextData): F[Unit]

  def many(tds: List[TextData]): F[Unit]

}

object SolrUpdate {
  private[this] val logger = getLogger

  def apply[F[_]: ConcurrentEffect](cfg: SolrConfig, client: Client[F]): SolrUpdate[F] = {
    val dsl = new Http4sClientDsl[F] {}
    import dsl._

    new SolrUpdate[F] {
      val url = (Uri.unsafeFromString(cfg.url.asString) / "update")
        .withQueryParam("commitWithin", cfg.commitWithin.toString)
        .withQueryParam("overwrite", "true")
        .withQueryParam("wt", "json")

      def single(td: TextData): F[Unit] = {
        val req = Method.POST(td.asJson, url)
        client.expect[String](req).map(r => logger.debug(s"Req: $req Response: $r"))
      }

      def many(tds: List[TextData]): F[Unit] = {
        val req = Method.POST(tds.asJson, url)
        client.expect[String](req).map(r => logger.debug(s"Req: $req Response: $r"))
      }
    }
  }
}
