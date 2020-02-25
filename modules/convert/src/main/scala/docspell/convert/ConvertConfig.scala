package docspell.convert

import docspell.convert.extern.{TesseractConfig, UnoconvConfig, WkHtmlPdfConfig}
import docspell.convert.flexmark.MarkdownConfig

case class ConvertConfig(
    chunkSize: Int,
    maxImageSize: Int,
    markdown: MarkdownConfig,
    wkhtmlpdf: WkHtmlPdfConfig,
    tesseract: TesseractConfig,
    unoconv: UnoconvConfig
)
