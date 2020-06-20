package docspell.ftsclient

import fs2.Stream
import docspell.common._

/** The fts client is the interface for docspell to a fulltext search
  * engine.
  *
  * It defines all operations required for integration into docspell.
  * It uses data structures from docspell. Implementation modules need
  * to translate it to the engine that provides the features.
  */
trait FtsClient[F[_]] {

  /** Initialization tasks. This is called exactly once and then never
    * again (except when re-indexing everything). It may be used to
    * setup the database.
    */
  def initialize: F[Unit]

  def search(q: FtsQuery): F[FtsResult]

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

}
