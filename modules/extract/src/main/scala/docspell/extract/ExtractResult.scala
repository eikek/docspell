/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract

import docspell.common.MimeType
import docspell.extract.pdfbox.PdfMetaData

sealed trait ExtractResult {

  def textOption: Option[String]

  def pdfMeta: Option[PdfMetaData]
}

object ExtractResult {

  case class UnsupportedFormat(mime: MimeType) extends ExtractResult {
    val textOption = None
    val pdfMeta    = None
  }
  def unsupportedFormat(mt: MimeType): ExtractResult =
    UnsupportedFormat(mt)

  case class Failure(ex: Throwable) extends ExtractResult {
    val textOption = None
    val pdfMeta    = None
  }
  def failure(ex: Throwable): ExtractResult =
    Failure(ex)

  case class Success(text: String, pdfMeta: Option[PdfMetaData]) extends ExtractResult {
    val textOption = Some(text)
    def appendPdfMetaToText: Success =
      pdfMeta.flatMap(_.asText) match {
        case Some(m) =>
          copy(text = text + "\n\n" + m)
        case None => this
      }
  }
  def success(text: String, pdfMeta: Option[PdfMetaData]): ExtractResult =
    Success(text, pdfMeta)

  def fromEither(e: Either[Throwable, String]): ExtractResult =
    e.fold(failure, str => success(str, None))

  def fromEitherResult(e: Either[Throwable, PdfExtract.Result]): ExtractResult =
    e.fold(failure, r => success(r.txt.value, r.meta))

}
