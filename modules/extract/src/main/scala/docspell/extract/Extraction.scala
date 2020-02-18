package docspell.extract

import cats.effect._
import cats.implicits._
import docspell.common._
import docspell.extract.ocr.{OcrType, TextExtract}
import docspell.extract.odf.{OdfExtract, OdfType}
import docspell.extract.poi.{PoiExtract, PoiType}
import docspell.extract.rtf.RtfExtract
import fs2.Stream
import docspell.files.TikaMimetype

trait Extraction[F[_]] {

  def extractText(data: Stream[F, Byte], dataType: DataType, lang: Language): F[ExtractResult]

}

object Extraction {

  def create[F[_]: Sync: ContextShift](
      blocker: Blocker,
      logger: Logger[F],
      cfg: ExtractConfig
  ): Extraction[F] =
    new Extraction[F] {
      def extractText(
          data: Stream[F, Byte],
          dataType: DataType,
          lang: Language
      ): F[ExtractResult] = {
        TikaMimetype.resolve(dataType, data).flatMap {
          case MimeType.pdf =>
            PdfExtract
              .get(data, blocker, lang, cfg.pdf.minTextLen, cfg.ocr, logger)
              .map(ExtractResult.fromEither)

          case PoiType(mt) =>
            PoiExtract.get(data, mt).map(ExtractResult.fromEither)

          case RtfExtract.rtfType =>
            RtfExtract.get(data).map(ExtractResult.fromEither)

          case OdfType(_) =>
            OdfExtract.get(data).map(ExtractResult.fromEither)

          case OcrType(_) =>
            TextExtract
              .extractOCR(data, blocker, logger, lang.iso3, cfg.ocr)
              .compile
              .lastOrError
              .attempt
              .map(ExtractResult.fromEither)

          case OdfType.container =>
            logger.info(s"File detected as ${OdfType.container}. Try to read as OpenDocument file.") *>
              OdfExtract.get(data).map(ExtractResult.fromEither)

          case mt =>
            ExtractResult.unsupportedFormat(mt).pure[F]

        }
      }
    }

}
