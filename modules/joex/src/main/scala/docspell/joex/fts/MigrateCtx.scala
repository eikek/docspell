package docspell.joex.fts

import docspell.common.Logger
import docspell.joex.Config
import docspell.store.Store
import docspell.ftsclient.FtsClient

case class MigrateCtx[F[_]](
    cfg: Config.FullTextSearch,
    store: Store[F],
    fts: FtsClient[F],
    logger: Logger[F]
)
