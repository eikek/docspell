/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.fts

import docspell.common.Logger
import docspell.ftsclient.FtsClient
import docspell.joex.Config
import docspell.joex.scheduler.Context
import docspell.store.Store

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
