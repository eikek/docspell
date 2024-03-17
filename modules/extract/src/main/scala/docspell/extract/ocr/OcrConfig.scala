/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.ocr

import fs2.io.file.Path

import docspell.common.exec.ExternalCommand

case class OcrConfig(
    maxImageSize: Int,
    ghostscript: OcrConfig.Ghostscript,
    pageRange: OcrConfig.PageRange,
    unpaper: OcrConfig.Unpaper,
    tesseract: OcrConfig.Tesseract
) {}

object OcrConfig {

  case class PageRange(begin: Int)

  case class Ghostscript(command: ExternalCommand, workingDir: Path)

  case class Tesseract(command: ExternalCommand)

  case class Unpaper(command: ExternalCommand)

}
