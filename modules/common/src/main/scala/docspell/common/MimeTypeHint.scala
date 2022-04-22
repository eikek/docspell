/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import fs2.io.file.Path

case class MimeTypeHint(filename: Option[String], advertised: Option[String]) {

  def withName(name: String): MimeTypeHint =
    copy(filename = Some(name))

  def withAdvertised(advertised: String): MimeTypeHint =
    copy(advertised = Some(advertised))
}

object MimeTypeHint {
  val none = MimeTypeHint(None, None)

  def filename(name: String): MimeTypeHint =
    MimeTypeHint(Some(name), None)

  def filename(file: Path): MimeTypeHint =
    filename(file.fileName.toString)

  def advertised(mimeType: MimeType): MimeTypeHint =
    advertised(mimeType.asString)

  def advertised(mimeType: String): MimeTypeHint =
    MimeTypeHint(None, Some(mimeType))
}
