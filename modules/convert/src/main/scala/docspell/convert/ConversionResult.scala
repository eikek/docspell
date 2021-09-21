/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert

import cats.data.Kleisli
import fs2.Stream

import docspell.common.MimeType

sealed trait ConversionResult[F[_]] {

  def pdfData: Stream[F, Byte]

}

object ConversionResult {

  /** The conversion is done by external tools that write files to the file system. These
    * are temporary files and they will be deleted once the process finishes. This handler
    * is used to do something relevant with the resulting files.
    */
  type Handler[F[_], A] = Kleisli[F, ConversionResult[F], A]

  def unsupportedFormat[F[_]](mime: MimeType): ConversionResult[F] =
    UnsupportedFormat[F](mime)

  def failure[F[_]](ex: Throwable): ConversionResult[F] =
    Failure[F](ex)

  def successPdf[F[_]](pdf: Stream[F, Byte]): ConversionResult[F] =
    SuccessPdf[F](pdf)

  def successPdfTxt[F[_]](pdf: Stream[F, Byte], txt: F[String]): ConversionResult[F] =
    SuccessPdfTxt[F](pdf, txt)

  def inputMalformed[F[_]](mimeType: MimeType, reason: String): ConversionResult[F] =
    InputMalformed(mimeType, reason)

  case class UnsupportedFormat[F[_]](mime: MimeType) extends ConversionResult[F] {
    val pdfData = Stream.empty
  }
  case class Failure[F[_]](ex: Throwable) extends ConversionResult[F] {
    val pdfData = Stream.empty
  }
  case class SuccessPdf[F[_]](pdf: Stream[F, Byte]) extends ConversionResult[F] {
    val pdfData = pdf
  }
  case class SuccessPdfTxt[F[_]](pdf: Stream[F, Byte], txt: F[String])
      extends ConversionResult[F] {
    val pdfData = pdf
  }

  case class InputMalformed[F[_]](mimeType: MimeType, reason: String)
      extends ConversionResult[F] {
    val pdfData = Stream.empty
  }
}
