/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert

import cats.data.NonEmptyList

import docspell.common.Password
import docspell.convert.ConvertConfig.DecryptPdf
import docspell.convert.extern._
import docspell.convert.flexmark.MarkdownConfig

final case class ConvertConfig(
    chunkSize: Int,
    convertedFilenamePart: String,
    maxImageSize: Int,
    markdown: MarkdownConfig,
    wkhtmlpdf: WkHtmlPdfConfig,
    weasyprint: WeasyprintConfig,
    htmlConverter: ConvertConfig.HtmlConverter,
    tesseract: TesseractConfig,
    unoconv: UnoconvConfig,
    ocrmypdf: OcrMyPdfConfig,
    decryptPdf: DecryptPdf
)

object ConvertConfig {

  final case class DecryptPdf(enabled: Boolean, passwords: List[Password])

  sealed trait HtmlConverter {
    def name: String
  }

  object HtmlConverter {
    case object Wkhtmltopdf extends HtmlConverter {
      val name = "wkhtmlpdf"
    }
    case object Weasyprint extends HtmlConverter {
      val name = "weasyprint"
    }
    val all: NonEmptyList[HtmlConverter] = NonEmptyList.of(Wkhtmltopdf, Weasyprint)

    def fromString(str: String): Either[String, HtmlConverter] =
      all
        .find(_.name.equalsIgnoreCase(str))
        .toRight(
          s"Invalid html-converter value: $str. Use one of: ${all.toList.mkString(", ")}"
        )
  }
}
