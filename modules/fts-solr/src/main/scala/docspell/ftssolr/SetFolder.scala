/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftssolr

import docspell.common._

final case class SetFolder(docId: Ident, folder: Option[Ident])
