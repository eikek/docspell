/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert

import docspell.convert.ConvertConfig.DecryptPdf
import docspell.convert.extern.OcrMyPdfConfig
import docspell.convert.extern.{TesseractConfig, UnoconvConfig, WkHtmlPdfConfig}
import docspell.convert.flexmark.MarkdownConfig

final case class ConvertConfig(
    chunkSize: Int,
    convertedFilenamePart: String,
    maxImageSize: Int,
    markdown: MarkdownConfig,
    wkhtmlpdf: WkHtmlPdfConfig,
    tesseract: TesseractConfig,
    unoconv: UnoconvConfig,
    ocrmypdf: OcrMyPdfConfig,
    decryptPdf: DecryptPdf
)

object ConvertConfig {

  final case class DecryptPdf(enabled: Boolean, passwords: List[String])
}
