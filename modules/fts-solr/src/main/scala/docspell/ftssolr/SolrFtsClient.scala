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
    (for {
      _      <- Stream.eval(logger.debug("Inserting data into index"))
      chunks <- data.chunks
      res    <- Stream.eval(solrUpdate.many(chunks.toList).attempt)
      _ <- res match {
        case Right(()) => Stream.emit(())
        case Left(ex) =>
          Stream.eval(logger.error(ex)("Error inserting chunk of data into index"))
      }
    } yield ()).compile.drain

  def updateIndex(logger: Logger[F], data: Stream[F, TextData]): F[Unit] = ???

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
