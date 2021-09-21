/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common._

case class FolderCount(id: Ident, name: String, owner: IdRef, count: Int)
