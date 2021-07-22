/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.ftssolr

import docspell.common._

final case class SetFolder(docId: Ident, folder: Option[Ident])
