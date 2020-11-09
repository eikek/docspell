package docspell.extract

import docspell.extract.ocr.OcrConfig
import docspell.extract.pdfbox.PreviewConfig

case class ExtractConfig(ocr: OcrConfig, pdf: PdfConfig, preview: PreviewConfig)
