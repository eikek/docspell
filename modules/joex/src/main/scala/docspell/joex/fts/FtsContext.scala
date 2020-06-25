package docspell.joex.fts

import docspell.common.Logger
import docspell.joex.Config
import docspell.joex.scheduler.Context
import docspell.store.Store
import docspell.ftsclient.FtsClient

case class FtsContext[F[_]](
    cfg: Config.FullTextSearch,
    store: Store[F],
    fts: FtsClient[F],
    logger: Logger[F]
)

object FtsContext {

  def apply[F[_]](
      cfg: Config.FullTextSearch,
      fts: FtsClient[F],
      ctx: Context[F, _]
  ): FtsContext[F] =
    FtsContext(cfg, ctx.store, fts, ctx.logger)
}
