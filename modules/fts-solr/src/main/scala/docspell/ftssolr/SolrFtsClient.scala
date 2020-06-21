package docspell.ftssolr

import fs2.Stream
import cats.effect._
import cats.implicits._
import org.http4s.client.Client

import docspell.common._
import docspell.ftsclient._

final class SolrFtsClient[F[_]: Effect](
    solrUpdate: SolrUpdate[F],
    solrSetup: SolrSetup[F],
    solrQuery: SolrQuery[F]
) extends FtsClient[F] {

  def initialize: F[Unit] =
    solrSetup.setupSchema

  def search(q: FtsQuery): F[FtsResult] =
    solrQuery.query(q)

  def indexData(logger: Logger[F], data: Stream[F, TextData]): F[Unit] =
    modifyIndex(logger, data)(solrUpdate.add)

  def updateIndex(logger: Logger[F], data: Stream[F, TextData]): F[Unit] =
    modifyIndex(logger, data)(solrUpdate.update)

  def modifyIndex(logger: Logger[F], data: Stream[F, TextData])(
      f: List[TextData] => F[Unit]
  ): F[Unit] =
    (for {
      _      <- Stream.eval(logger.debug("Updating SOLR index"))
      chunks <- data.chunks
      res    <- Stream.eval(f(chunks.toList).attempt)
      _ <- res match {
        case Right(()) => Stream.emit(())
        case Left(ex) =>
          Stream.eval(logger.error(ex)("Error updating with chunk of data"))
      }
    } yield ()).compile.drain

  def clearAll(logger: Logger[F]): F[Unit] =
    logger.info("Deleting complete full-text index!") *>
      solrUpdate.delete("*:*")

  def clear(logger: Logger[F], collective: Ident): F[Unit] =
    logger.info(s"Deleting full-text index for collective ${collective.id}") *>
      solrUpdate.delete(s"${Field.collectiveId.name}:${collective.id}")
}

object SolrFtsClient {

  def apply[F[_]: ConcurrentEffect](
      cfg: SolrConfig,
      httpClient: Client[F]
  ): Resource[F, FtsClient[F]] =
    Resource.pure[F, FtsClient[F]](
      new SolrFtsClient(
        SolrUpdate(cfg, httpClient),
        SolrSetup(cfg, httpClient),
        SolrQuery(cfg, httpClient)
      )
    )

}
