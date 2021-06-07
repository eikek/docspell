package docspell.ftssolr

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.ftsclient._
import docspell.ftssolr.JsonCodec._

import _root_.io.circe._
import _root_.io.circe.syntax._
import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe._
import org.http4s.client.Client
import org.http4s.client.dsl.Http4sClientDsl

trait SolrUpdate[F[_]] {

  def add(tds: List[TextData]): F[Unit]

  def update(tds: List[TextData]): F[Unit]

  def updateFolder(itemId: Ident, collective: Ident, folder: Option[Ident]): F[Unit]

  def updateVersionDoc(doc: VersionDoc): F[Unit]

  def delete(q: String, commitWithin: Option[Int]): F[Unit]
}

object SolrUpdate {

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
        client.expect[Unit](req)
      }

      def update(tds: List[TextData]): F[Unit] = {
        val req = Method.POST(tds.filter(minOneChange).map(SetFields).asJson, url)
        client.expect[Unit](req)
      }

      def updateVersionDoc(doc: VersionDoc): F[Unit] = {
        val req = Method.POST(List(doc).asJson, url)
        client.expect[Unit](req)
      }

      def updateFolder(
          itemId: Ident,
          collective: Ident,
          folder: Option[Ident]
      ): F[Unit] = {
        val queryUrl = Uri.unsafeFromString(cfg.url.asString) / "query"
        val q = QueryData(
          "*:*",
          s"${Field.itemId.name}:${itemId.id} AND ${Field.collectiveId.name}:${collective.id}",
          Int.MaxValue,
          0,
          List(Field.id),
          Map.empty
        )
        val searchReq = Method.POST(q.asJson, queryUrl)
        for {
          docIds <- client.expect[DocIdResult](searchReq)
          sets = docIds.toSetFolder(folder)
          req  = Method.POST(sets.asJson, url)
          _ <- client.expect[Unit](req)
        } yield ()
      }

      def delete(q: String, commitWithin: Option[Int]): F[Unit] = {
        val uri = commitWithin match {
          case Some(n) =>
            if (n <= 0)
              url.removeQueryParam("commitWithin").withQueryParam("commit", "true")
            else url.withQueryParam("commitWithin", n.toString)
          case None =>
            url
        }
        val req = Method.POST(Delete(q).asJson, uri)
        client.expect[Unit](req)
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
