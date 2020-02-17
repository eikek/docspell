package docspell.extract.ocr

import cats.effect.{Blocker, ContextShift, Sync}
import docspell.common._
import docspell.files._
import fs2.Stream

object TextExtract {

  def extract[F[_]: Sync: ContextShift](
      in: Stream[F, Byte],
      blocker: Blocker,
      lang: String,
      config: OcrConfig
  ): Stream[F, String] =
    extractOCR(in, blocker, lang, config)

  def extractOCR[F[_]: Sync: ContextShift](
      in: Stream[F, Byte],
      blocker: Blocker,
      lang: String,
      config: OcrConfig
  ): Stream[F, String] =
    Stream
      .eval(TikaMimetype.detect(in, MimeTypeHint.none))
      .flatMap({
        case mt if !config.isAllowed(mt) =>
          raiseError(s"File `$mt` not allowed")

        case MimeType.pdf =>
          Ocr.extractPdf(in, blocker, lang, config)

        case mt if mt.primary == "image" =>
          Ocr.extractImage(in, blocker, lang, config)

        case mt =>
          raiseError(s"File `$mt` not supported")
      })

  private def raiseError[F[_]: Sync](msg: String): Stream[F, Nothing] =
    Stream.raiseError[F](new Exception(msg))
}
