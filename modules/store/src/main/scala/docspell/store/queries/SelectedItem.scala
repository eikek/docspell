/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common._

/** Some preselected item from a fulltext search. */
case class SelectedItem(itemId: Ident, weight: Double)
