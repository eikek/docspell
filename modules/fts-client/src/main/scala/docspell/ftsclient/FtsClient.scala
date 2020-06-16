package docspell.ftsclient

import fs2.Stream

/** The fts client is the interface for docspell to a fulltext search
  * engine.
  *
  * It defines all operations required for integration into docspell.
  * It uses data structures and terms of docspell. Implementation
  * modules need to translate it to the engine that provides the
  * features.
  */
trait FtsClient[F[_]] {

  def searchBasic(q: FtsQuery): Stream[F, FtsBasicResult]

  def indexData(data: Stream[F, TextData]): F[Unit]
}
