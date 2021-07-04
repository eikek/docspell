/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.syntax

import docspell.common._

import bitpeace.Mimetype

object MimeTypes {

  implicit final class BitpeaceMimeTypeOps(bmt: Mimetype) {

    def toLocal: MimeType =
      MimeType(bmt.primary, bmt.sub, bmt.params)
  }

  implicit final class EmilMimeTypeOps(emt: emil.MimeType) {
    def toLocal: MimeType =
      MimeType(emt.primary, emt.sub, emt.params)
  }

  implicit final class DocspellMimeTypeOps(mt: MimeType) {
    def toEmil: emil.MimeType =
      emil.MimeType(mt.primary, mt.sub, mt.params)

    def toBitpeace: Mimetype =
      Mimetype(mt.primary, mt.sub, mt.params)
  }
}
