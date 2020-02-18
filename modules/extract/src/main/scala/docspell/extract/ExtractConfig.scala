package docspell.extract

import docspell.extract.ocr.OcrConfig

case class ExtractConfig(maxImageSize: Int, ocr: OcrConfig, pdf: PdfConfig)
