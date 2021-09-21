/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftssolr

import docspell.common._

final case class SolrConfig(
    url: LenientUri,
    commitWithin: Int,
    logVerbose: Boolean,
    defType: String,
    qOp: String
)

object SolrConfig {}
