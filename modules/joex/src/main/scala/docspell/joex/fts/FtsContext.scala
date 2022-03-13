/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.fts

import docspell.backend.fulltext.CreateIndex
import docspell.ftsclient.FtsClient
import docspell.joex.Config
import docspell.logging.Logger
import docspell.store.Store

final case class FtsContext[F[_]](
    cfg: Config.FullTextSearch,
    store: Store[F],
    fulltext: CreateIndex[F],
    fts: FtsClient[F],
    logger: Logger[F]
)
