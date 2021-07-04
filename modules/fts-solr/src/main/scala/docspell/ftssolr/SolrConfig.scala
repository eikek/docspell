/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
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
