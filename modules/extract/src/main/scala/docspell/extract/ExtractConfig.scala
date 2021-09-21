/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract

import docspell.extract.ocr.OcrConfig
import docspell.extract.pdfbox.PreviewConfig

case class ExtractConfig(ocr: OcrConfig, pdf: PdfConfig, preview: PreviewConfig)
