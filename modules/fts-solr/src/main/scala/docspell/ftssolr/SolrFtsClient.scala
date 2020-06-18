package docspell.ftssolr

import fs2.Stream
import cats.effect._
import cats.implicits._
import org.http4s.client.Client

import cats.data.NonEmptyList
import docspell.common._
import docspell.ftsclient._
import docspell.ftsclient.FtsBasicResult._

final class SolrFtsClient[F[_]: Effect](
    solrUpdate: SolrUpdate[F]
) extends FtsClient[F] {

  def initialize: F[Unit] =
    ().pure[F]

  def searchBasic(q: FtsQuery): Stream[F, FtsBasicResult] =
    Stream.emits(
      Seq(
        FtsBasicResult(
          Ident.unsafe("5J4zvCiTE2j-UEznDUsUCsA-5px6ftrSwfs-FpUWCaHh2Ei"),
          NonEmptyList.of(AttachmentMatch(Ident.unsafe("a"), 0.2))
        ),
        FtsBasicResult(
          Ident.unsafe("8B8UNoC1U4y-dqnqjdFG7ue-LG5ktz9pWVt-diFemCLrLAa"),
          NonEmptyList.of(AttachmentMatch(Ident.unsafe("b"), 0.5))
        )
      )
    )

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

}

object SolrFtsClient {

  def apply[F[_]: ConcurrentEffect](
      cfg: SolrConfig,
      httpClient: Client[F]
  ): Resource[F, FtsClient[F]] =
    Resource.pure[F, FtsClient[F]](
      new SolrFtsClient(SolrUpdate(cfg, httpClient))
    )

}
