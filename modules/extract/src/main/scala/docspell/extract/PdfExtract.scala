package docspell.extract

import cats.implicits._
import cats.effect._
import fs2.Stream
import docspell.common.{Language, Logger}
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
  ): F[Either[Throwable, String]] = {

    val runOcr =
      TextExtract.extractOCR(in, blocker, lang.iso3, ocrCfg).compile.lastOrError

    def chooseResult(ocrStr: String, strippedStr: String) =
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
      pdfboxRes <- PdfboxExtract.get[F](in)
      res <- pdfboxRes.fold(
        ex =>
          logger.info(
            s"Stripping text from PDF resulted in an error: ${ex.getMessage}. Trying with OCR. "
          ) *> runOcr.attempt,
        str =>
          if (str.length >= stripMinLen) str.pure[F].attempt
          else
            logger
              .info(s"Stripping text from PDF is very small (${str.length}). Trying with OCR.") *>
              runOcr.flatMap(ocrStr => chooseResult(ocrStr, str)).attempt
      )
    } yield res
  }
}
