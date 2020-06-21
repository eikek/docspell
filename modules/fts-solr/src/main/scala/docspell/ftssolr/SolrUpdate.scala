package docspell.ftssolr

import cats.effect._
import org.http4s._
import cats.implicits._
import org.http4s.client.Client
import org.http4s.circe._
import org.http4s.client.dsl.Http4sClientDsl
import _root_.io.circe._
import _root_.io.circe.syntax._
import org.log4s.getLogger

import docspell.ftsclient._
import JsonCodec._

trait SolrUpdate[F[_]] {

  def add(tds: List[TextData]): F[Unit]

  def update(tds: List[TextData]): F[Unit]

  def delete(q: String): F[Unit]
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


      def add(tds: List[TextData]): F[Unit] = {
        val req = Method.POST(tds.asJson, url)
        client.expect[String](req).map(r => logger.debug(s"Req: $req Response: $r"))
      }

      def update(tds: List[TextData]): F[Unit] = {
        val req = Method.POST(tds.filter(minOneChange).map(SetFields).asJson, url)
        client.expect[String](req).map(r => logger.debug(s"Req: $req Response: $r"))
      }

      def delete(q: String): F[Unit] = {
        val req = Method.POST(Delete(q).asJson, url)
        client.expect[String](req).map(r => logger.debug(s"Req: $req Response: $r"))
      }

      private val minOneChange: TextData => Boolean =
        _ match {
          case td: TextData.Attachment =>
            td.name.isDefined || td.text.isDefined
          case td: TextData.Item =>
            td.name.isDefined || td.notes.isDefined
        }
    }
    }

    case class Delete(query: String)
    object Delete {
      implicit val jsonEncoder: Encoder[Delete] =
        new Encoder[Delete] {
          def apply(d: Delete): Json =
            Json.obj(
              ("delete", Json.obj("query" -> d.query.asJson))
            )
        }
    }
}
