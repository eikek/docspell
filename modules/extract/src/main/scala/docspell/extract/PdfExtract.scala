package docspell.extract

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common.{Language, Logger}
import docspell.extract.internal.Text
import docspell.extract.ocr.{OcrConfig, TextExtract}
import docspell.extract.pdfbox.PdfMetaData
import docspell.extract.pdfbox.PdfboxExtract

object PdfExtract {
  final case class Result(txt: Text, meta: Option[PdfMetaData])
  object Result {
    def apply(t: (Text, Option[PdfMetaData])): Result =
      Result(t._1, t._2)
  }

  def get[F[_]: Async](
      in: Stream[F, Byte],
      lang: Language,
      stripMinLen: Int,
      ocrCfg: OcrConfig,
      logger: Logger[F]
  ): F[Either[Throwable, Result]] = {

    val runOcr =
      TextExtract.extractOCR(in, logger, lang.iso3, ocrCfg).compile.lastOrError

    def chooseResult(ocrStr: Text, strippedRes: (Text, Option[PdfMetaData])) =
      if (ocrStr.length > strippedRes._1.length)
        logger.info(
          s"Using OCR text, as it is longer (${ocrStr.length} > ${strippedRes._1.length})"
        ) *> Result(ocrStr, strippedRes._2).pure[F]
      else
        logger.info(
          s"Using stripped text (not OCR), as it is longer (${strippedRes._1.length} > ${ocrStr.length})"
        ) *> Result(strippedRes).pure[F]

    //maybe better: inspect the pdf and decide whether ocr or not
    for {
      pdfboxRes <-
        logger.debug("Trying to strip text from pdf using pdfbox.") *>
          PdfboxExtract.getTextAndMetaData[F](in)
      res <- pdfboxRes.fold(
        ex =>
          logger.info(
            s"Stripping text from PDF resulted in an error: ${ex.getMessage}. Trying with OCR. "
          ) >> runOcr.map(txt => Result(txt, None)).attempt,
        pair =>
          if (pair._1.length >= stripMinLen) Result(pair).pure[F].attempt
          else
            logger
              .info(
                s"Stripped text from PDF is small (${pair._1.length}). Trying with OCR."
              ) *>
              runOcr.flatMap(ocrStr => chooseResult(ocrStr, pair)).attempt
      )
    } yield res
  }
}
