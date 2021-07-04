/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.convert

import java.nio.charset.StandardCharsets

import cats.effect._
import cats.implicits._
import fs2._

import docspell.common._
import docspell.convert.ConversionResult.Handler
import docspell.convert.extern._
import docspell.convert.flexmark.Markdown
import docspell.files.{ImageSize, TikaMimetype}

import scodec.bits.ByteVector

trait Conversion[F[_]] {

  def toPDF[A](dataType: DataType, lang: Language, handler: Handler[F, A])(
      in: Stream[F, Byte]
  ): F[A]

}

object Conversion {

  def create[F[_]: Async](
      cfg: ConvertConfig,
      sanitizeHtml: SanitizeHtml,
      logger: Logger[F]
  ): Resource[F, Conversion[F]] =
    Resource.pure[F, Conversion[F]](new Conversion[F] {

      def toPDF[A](dataType: DataType, lang: Language, handler: Handler[F, A])(
          in: Stream[F, Byte]
      ): F[A] =
        TikaMimetype.resolve(dataType, in).flatMap {
          case MimeType.PdfMatch(_) =>
            OcrMyPdf
              .toPDF(cfg.ocrmypdf, lang, cfg.chunkSize, logger)(in, handler)

          case MimeType.HtmlMatch(mt) =>
            val cs = mt.charsetOrUtf8
            WkHtmlPdf
              .toPDF(cfg.wkhtmlpdf, cfg.chunkSize, cs, sanitizeHtml, logger)(
                in,
                handler
              )

          case MimeType.TextAllMatch(mt) =>
            val cs = mt.charsetOrUtf8
            Markdown.toHtml(in, cfg.markdown, cs).flatMap { html =>
              val bytes = Stream
                .chunk(
                  Chunk.byteVector(ByteVector.view(html.getBytes(StandardCharsets.UTF_8)))
                )
                .covary[F]
              WkHtmlPdf.toPDF(
                cfg.wkhtmlpdf,
                cfg.chunkSize,
                StandardCharsets.UTF_8,
                sanitizeHtml,
                logger
              )(bytes, handler)
            }

          case MimeType.ImageMatch(mt) =>
            ImageSize.get(in).flatMap {
              case Some(dim) =>
                if (dim.product > cfg.maxImageSize)
                  logger
                    .info(
                      s"Image size (${dim.product}) is too large (max ${cfg.maxImageSize})."
                    ) *>
                    handler.run(
                      ConversionResult.inputMalformed(
                        mt,
                        s"Image size (${dim.width}x${dim.height}) is too large (max ${cfg.maxImageSize})."
                      )
                    )
                else
                  Tesseract.toPDF(cfg.tesseract, lang, cfg.chunkSize, logger)(
                    in,
                    handler
                  )

              case None =>
                logger.info(
                  s"Cannot read image when determining size for ${mt.asString}. Converting anyways."
                ) *>
                  Tesseract.toPDF(cfg.tesseract, lang, cfg.chunkSize, logger)(
                    in,
                    handler
                  )
            }

          case Office(_) =>
            Unoconv.toPDF(cfg.unoconv, cfg.chunkSize, logger)(in, handler)

          case mt =>
            handler.run(ConversionResult.unsupportedFormat(mt))
        }
    })

  object Office {
    val odt      = MimeType.application("vnd.oasis.opendocument.text")
    val ods      = MimeType.application("vnd.oasis.opendocument.spreadsheet")
    val odtAlias = MimeType.application("x-vnd.oasis.opendocument.text")
    val odsAlias = MimeType.application("x-vnd.oasis.opendocument.spreadsheet")
    val msoffice = MimeType.application("x-tika-msoffice")
    val ooxml    = MimeType.application("x-tika-ooxml")
    val docx =
      MimeType.application("vnd.openxmlformats-officedocument.wordprocessingml.document")
    val xlsx =
      MimeType.application("vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    val xls = MimeType.application("vnd.ms-excel")
    val doc = MimeType.application("msword")
    val rtf = MimeType.application("rtf")

    // without a filename, tika returns application/zip for odt/ods files, since
    // they are just zip files
    val odfContainer = MimeType.zip

    val all =
      Set(
        odt,
        ods,
        odtAlias,
        odsAlias,
        msoffice,
        ooxml,
        docx,
        xlsx,
        xls,
        doc,
        rtf,
        odfContainer
      )

    def unapply(m: MimeType): Option[MimeType] =
      Some(m).map(_.baseType).filter(all.contains)
  }

  def unapply(mt: MimeType): Option[MimeType] =
    mt match {
      case Office(_)                => Some(mt)
      case MimeType.TextAllMatch(_) => Some(mt)
      case MimeType.ImageMatch(_)   => Some(mt)
      case _                        => None
    }
}
