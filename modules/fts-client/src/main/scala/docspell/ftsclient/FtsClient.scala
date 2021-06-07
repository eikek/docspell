package docspell.ftsclient

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._

import org.log4s.getLogger

/** The fts client is the interface for docspell to a fulltext search
  * engine.
  *
  * It defines all operations required for integration into docspell.
  * It uses data structures from docspell. Implementation modules need
  * to translate it to the engine that provides the features.
  */
trait FtsClient[F[_]] {

  /** Initialization tasks. This can be used to setup the fulltext
    * search engine. The implementation is expected to keep track of
    * run migrations, so that running these is idempotent. For
    * example, it may be run on each application start.
    *
    * Initialization may involve re-indexing all data, therefore it
    * must run outside the scope of this client. The migration may
    * include a task that applies any work and/or it can return a
    * result indicating that after this task a re-index is necessary.
    */
  def initialize: F[List[FtsMigration[F]]]

  /** A list of initialization tasks that can be run when re-creating
    * the index.
    *
    * This is not run on startup, but only when required, for example
    * when re-creating the entire index.
    */
  def initializeNew: List[FtsMigration[F]]

  /** Run a full-text search. */
  def search(q: FtsQuery): F[FtsResult]

  /** Continually run a full-text search and concatenate the results. */
  def searchAll(q: FtsQuery): Stream[F, FtsResult] =
    Stream.eval(search(q)).flatMap { result =>
      if (result.results.size < q.limit) Stream.emit(result)
      else Stream.emit(result) ++ searchAll(q.nextPage)
    }

  /** Push all data to the index. Data with same `id' is replaced.
    * Values that are `None' are removed from the index (or set to an
    * empty string).
    */
  def indexData(logger: Logger[F], data: Stream[F, TextData]): F[Unit]

  def indexData(logger: Logger[F], data: TextData*): F[Unit] =
    indexData(logger, Stream.emits(data))

  /** Push all data to the index, but only update existing entries. No
    * new entries are created and values that are given as `None' are
    * skipped.
    */
  def updateIndex(logger: Logger[F], data: Stream[F, TextData]): F[Unit]

  def updateIndex(logger: Logger[F], data: TextData*): F[Unit] =
    updateIndex(logger, Stream.emits(data))

  def updateItemName(
      logger: Logger[F],
      itemId: Ident,
      collective: Ident,
      name: String
  ): F[Unit] =
    updateIndex(logger, TextData.item(itemId, collective, None, Some(name), None))

  def updateItemNotes(
      logger: Logger[F],
      itemId: Ident,
      collective: Ident,
      notes: Option[String]
  ): F[Unit] =
    updateIndex(
      logger,
      TextData.item(itemId, collective, None, None, Some(notes.getOrElse("")))
    )

  def updateAttachmentName(
      logger: Logger[F],
      itemId: Ident,
      attachId: Ident,
      collective: Ident,
      name: Option[String]
  ): F[Unit] =
    updateIndex(
      logger,
      TextData.attachment(
        itemId,
        attachId,
        collective,
        None,
        Language.English,
        Some(name.getOrElse("")),
        None
      )
    )

  def updateFolder(
      logger: Logger[F],
      itemId: Ident,
      collective: Ident,
      folder: Option[Ident]
  ): F[Unit]

  def removeItem(logger: Logger[F], itemId: Ident): F[Unit]

  def removeAttachment(logger: Logger[F], attachId: Ident): F[Unit]

  /** Clears the index – removes everything. */
  def clearAll(logger: Logger[F]): F[Unit]

  /** Clears the index from all data belonging to the given collective. */
  def clear(logger: Logger[F], collective: Ident): F[Unit]

}

object FtsClient {

  def none[F[_]: Sync] =
    new FtsClient[F] {
      private[this] val logger = Logger.log4s[F](getLogger)

      def initialize: F[List[FtsMigration[F]]] =
        Sync[F].pure(Nil)

      def initializeNew: List[FtsMigration[F]] =
        Nil

      def search(q: FtsQuery): F[FtsResult] =
        logger.warn("Full-text search is disabled!") *> FtsResult.empty.pure[F]

      def updateIndex(logger: Logger[F], data: Stream[F, TextData]): F[Unit] =
        logger.warn("Full-text search is disabled!")

      def updateFolder(
          logger: Logger[F],
          itemId: Ident,
          collective: Ident,
          folder: Option[Ident]
      ): F[Unit] =
        logger.warn("Full-text search is disabled!")

      def indexData(logger: Logger[F], data: Stream[F, TextData]): F[Unit] =
        logger.warn("Full-text search is disabled!")

      def removeItem(logger: Logger[F], itemId: Ident): F[Unit] =
        logger.warn("Full-text search is disabled!")

      def removeAttachment(logger: Logger[F], attachId: Ident): F[Unit] =
        logger.warn("Full-text search is disabled!")

      def clearAll(logger: Logger[F]): F[Unit] =
        logger.warn("Full-text search is disabled!")

      def clear(logger: Logger[F], collective: Ident): F[Unit] =
        logger.warn("Full-text search is disabled!")
    }
}
