package docspell.extract.ocr

import cats.effect.{Blocker, ContextShift, Sync}
import fs2.Stream

import docspell.common._
import docspell.extract.internal.Text
import docspell.files._

object TextExtract {

  def extract[F[_]: Sync: ContextShift](
      in: Stream[F, Byte],
      blocker: Blocker,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, Text] =
    extractOCR(in, blocker, logger, lang, config)

  def extractOCR[F[_]: Sync: ContextShift](
      in: Stream[F, Byte],
      blocker: Blocker,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, Text] =
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
      .map(Text.apply)

  private def raiseError[F[_]: Sync](msg: String): Stream[F, Nothing] =
    Stream.raiseError[F](new Exception(msg))
}
