/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common._

/** Some preselected item from a fulltext search. */
case class SelectedItem(itemId: Ident, weight: Double)
