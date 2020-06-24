package docspell.ftssolr

import fs2.Stream
import cats.effect._
import cats.implicits._
import org.http4s.client.Client
import org.http4s.client.middleware.Logger
import org.log4s.getLogger

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

  def removeItem(logger: Logger[F], itemId: Ident): F[Unit] =
    logger.debug(s"Remove item '${itemId.id}' from index") *>
      solrUpdate.delete(s"${Field.itemId.name}:${itemId.id}")

  def removeAttachment(logger: Logger[F], attachId: Ident): F[Unit] =
    logger.debug(s"Remove attachment '${attachId.id}' from index") *>
      solrUpdate.delete(s"${Field.attachmentId.name}:${attachId.id}")

  def clearAll(logger: Logger[F]): F[Unit] =
    logger.info("Deleting complete full-text index!") *>
      solrUpdate.delete("*:*")

  def clear(logger: Logger[F], collective: Ident): F[Unit] =
    logger.info(s"Deleting full-text index for collective ${collective.id}") *>
      solrUpdate.delete(s"${Field.collectiveId.name}:${collective.id}")
}

object SolrFtsClient {
  private[this] val logger = getLogger

  def apply[F[_]: ConcurrentEffect](
      cfg: SolrConfig,
      httpClient: Client[F]
  ): Resource[F, FtsClient[F]] = {
    val client = loggingMiddleware(cfg, httpClient)
    Resource.pure[F, FtsClient[F]](
      new SolrFtsClient(
        SolrUpdate(cfg, client),
        SolrSetup(cfg, client),
        SolrQuery(cfg, client)
      )
    )
  }

  private def loggingMiddleware[F[_]: Concurrent](
      cfg: SolrConfig,
      client: Client[F]
  ): Client[F] =
    Logger(
      logHeaders = true,
      logBody = cfg.logVerbose,
      logAction = Some((msg: String) => Sync[F].delay(logger.trace(msg)))
    )(client)

}
