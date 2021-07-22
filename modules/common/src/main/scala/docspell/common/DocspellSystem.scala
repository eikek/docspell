/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

object DocspellSystem {

  val user                    = Ident.unsafe("docspell-system")
  val taskGroup               = user
  val migrationTaskTracker    = Ident.unsafe("full-text-index-tracker")
  val allPreviewTaskTracker   = Ident.unsafe("generate-all-previews")
  val allPageCountTaskTracker = Ident.unsafe("all-page-count-tracker")
}
