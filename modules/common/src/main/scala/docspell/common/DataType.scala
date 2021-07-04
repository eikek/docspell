/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

sealed trait DataType {}

object DataType {

  case class Exact(mime: MimeType) extends DataType

  case class Hint(hint: MimeTypeHint) extends DataType

  def apply(mt: MimeType): DataType =
    Exact(mt)

  def filename(name: String): DataType =
    Hint(MimeTypeHint.filename(name))
}
