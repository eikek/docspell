package docspell.ftssolr

import fs2.Stream
import docspell.ftsclient._

final class SolrFtsClient[F[_]] extends FtsClient[F] {

  def searchBasic(q: FtsQuery): Stream[F, FtsBasicResult] =
    ???
  def indexData(data: TextData): F[Unit] =
    ???
}
