/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.extract

import docspell.extract.ocr.OcrConfig
import docspell.extract.pdfbox.PreviewConfig

case class ExtractConfig(ocr: OcrConfig, pdf: PdfConfig, preview: PreviewConfig)
