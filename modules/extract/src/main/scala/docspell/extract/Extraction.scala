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
import docspell.files.ImageSize

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
      ): F[ExtractResult] =
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

          case OcrType(mt) =>
            val doExtract = TextExtract
              .extractOCR(data, blocker, logger, lang.iso3, cfg.ocr)
              .compile
              .lastOrError
              .map(_.trim)
              .attempt
              .map(ExtractResult.fromEither)

            ImageSize.get(data).flatMap {
              case Some(dim) =>
                if (dim.product > cfg.ocr.maxImageSize) {
                  logger.info(
                    s"Image size (${dim.product}) is too large (max ${cfg.ocr.maxImageSize})."
                  ) *>
                    ExtractResult
                      .failure(
                        new Exception(
                          s"Image size (${dim.width}x${dim.height}) is too large (max ${cfg.ocr.maxImageSize})."
                        )
                      )
                      .pure[F]
                } else {
                  doExtract
                }
              case None =>
                logger.info(s"Cannot read image data from ${mt.asString}. Extracting anyways.") *>
                  doExtract
            }

          case OdfType.container =>
            logger
              .info(s"File detected as ${OdfType.container}. Try to read as OpenDocument file.") *>
              OdfExtract.get(data).map(ExtractResult.fromEither)

          case mt @ MimeType("text", sub) if !sub.contains("html") =>
            logger.info(s"File detected as ${mt.asString}. Returning itself as text.") *>
              data.through(fs2.text.utf8Decode).compile.last.map { txt =>
                ExtractResult.success(txt.getOrElse("").trim)
              }

          case mt =>
            ExtractResult.unsupportedFormat(mt).pure[F]

        }
    }

}
