package docspell.extract

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.extract.internal.Text
import docspell.extract.ocr.{OcrType, TextExtract}
import docspell.extract.odf.{OdfExtract, OdfType}
import docspell.extract.poi.{PoiExtract, PoiType}
import docspell.extract.rtf.RtfExtract
import docspell.files.ImageSize
import docspell.files.TikaMimetype

trait Extraction[F[_]] {

  def extractText(
      data: Stream[F, Byte],
      dataType: DataType,
      lang: Language
  ): F[ExtractResult]

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
          case MimeType.PdfMatch(_) =>
            PdfExtract
              .get(data, blocker, lang, cfg.pdf.minTextLen, cfg.ocr, logger)
              .map(ExtractResult.fromEitherResult)

          case PoiType(mt) =>
            PoiExtract
              .get(data, mt)
              .map(_.map(_.value))
              .map(ExtractResult.fromEither)

          case RtfExtract.rtfType =>
            RtfExtract.get(data).map(_.map(_.value)).map(ExtractResult.fromEither)

          case OdfType(_) =>
            OdfExtract
              .get(data)
              .map(_.map(_.value))
              .map(ExtractResult.fromEither)

          case OcrType(mt) =>
            val doExtract = TextExtract
              .extractOCR(data, blocker, logger, lang.iso3, cfg.ocr)
              .compile
              .lastOrError
              .map(_.value)
              .attempt
              .map(ExtractResult.fromEither)

            ImageSize.get(data).flatMap {
              case Some(dim) =>
                if (dim.product > cfg.ocr.maxImageSize)
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
                else
                  doExtract
              case None =>
                logger.info(
                  s"Cannot read image data from ${mt.asString}. Extracting anyways."
                ) *>
                  doExtract
            }

          case OdfType.ContainerMatch(_) =>
            logger
              .info(
                s"File detected as ${OdfType.container}. Try to read as OpenDocument file."
              ) *>
              OdfExtract
                .get(data)
                .map(_.map(_.value))
                .map(ExtractResult.fromEither)

          case MimeType.NonHtmlText(mt) =>
            val cs = mt.charsetOrUtf8
            logger.info(s"File detected as ${mt.asString}. Returning itself as text.") *>
              data.through(Binary.decode(cs)).foldMonoid.compile.last.map { txt =>
                ExtractResult.success(Text(txt).value, None)
              }

          case mt =>
            ExtractResult.unsupportedFormat(mt).pure[F]

        }
    }

}
