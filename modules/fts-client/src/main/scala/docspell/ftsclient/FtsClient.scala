package docspell.ftsclient

import fs2.Stream
import docspell.common._

/** The fts client is the interface for docspell to a fulltext search
  * engine.
  *
  * It defines all operations required for integration into docspell.
  * It uses data structures and terms of docspell. Implementation
  * modules need to translate it to the engine that provides the
  * features.
  */
trait FtsClient[F[_]] {

  /** Optional operation to do some initialization tasks. This is called
    * exactly once and then never again. It may be used to setup the
    * database.
    */
  def initialize: F[Unit]

  def searchBasic(q: FtsQuery): Stream[F, FtsBasicResult]

  def indexData(logger: Logger[F], data: Stream[F, TextData]): F[Unit]
}
