package docspell.extract.ocr

import cats.effect.{Blocker, ContextShift, Sync}
import docspell.common._
import docspell.files._
import fs2.Stream

object TextExtract {

  def extract[F[_]: Sync: ContextShift](
      in: Stream[F, Byte],
      blocker: Blocker,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, String] =
    extractOCR(in, blocker, logger, lang, config)

  def extractOCR[F[_]: Sync: ContextShift](
      in: Stream[F, Byte],
      blocker: Blocker,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, String] =
    Stream
      .eval(TikaMimetype.detect(in, MimeTypeHint.none))
      .flatMap({
        case MimeType.pdf =>
          Stream.eval(Ocr.extractPdf(in, blocker, logger, lang, config)).unNoneTerminate

        case mt if mt.primary == "image" =>
          Ocr.extractImage(in, blocker, logger, lang, config)

        case mt =>
          raiseError(s"File `$mt` not supported")
      })

  private def raiseError[F[_]: Sync](msg: String): Stream[F, Nothing] =
    Stream.raiseError[F](new Exception(msg))
}
