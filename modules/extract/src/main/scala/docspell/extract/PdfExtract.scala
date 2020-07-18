package docspell.extract

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common.{Language, Logger}
import docspell.extract.internal.Text
import docspell.extract.ocr.{OcrConfig, TextExtract}
import docspell.extract.pdfbox.PdfboxExtract

object PdfExtract {

  def get[F[_]: Sync: ContextShift](
      in: Stream[F, Byte],
      blocker: Blocker,
      lang: Language,
      stripMinLen: Int,
      ocrCfg: OcrConfig,
      logger: Logger[F]
  ): F[Either[Throwable, Text]] = {

    val runOcr =
      TextExtract.extractOCR(in, blocker, logger, lang.iso3, ocrCfg).compile.lastOrError

    def chooseResult(ocrStr: Text, strippedStr: Text) =
      if (ocrStr.length > strippedStr.length)
        logger.info(
          s"Using OCR text, as it is longer (${ocrStr.length} > ${strippedStr.length})"
        ) *> ocrStr.pure[F]
      else
        logger.info(
          s"Using stripped text (not OCR), as it is longer (${strippedStr.length} > ${ocrStr.length})"
        ) *> strippedStr.pure[F]

    //maybe better: inspect the pdf and decide whether ocr or not
    for {
      pdfboxRes <-
        logger.debug("Trying to strip text from pdf using pdfbox.") *> PdfboxExtract
          .getText[F](in)
      res <- pdfboxRes.fold(
        ex =>
          logger.info(
            s"Stripping text from PDF resulted in an error: ${ex.getMessage}. Trying with OCR. "
          ) >> runOcr.attempt,
        str =>
          if (str.length >= stripMinLen) str.pure[F].attempt
          else
            logger
              .info(
                s"Stripped text from PDF is small (${str.length}). Trying with OCR."
              ) *>
              runOcr.flatMap(ocrStr => chooseResult(ocrStr, str)).attempt
      )
    } yield res
  }
}
