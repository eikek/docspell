/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common._

case class AttachmentLight(
    id: Ident,
    position: Int,
    name: Option[String],
    pageCount: Option[Int]
)
