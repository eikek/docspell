package docspell.extract.rtf

import java.io.{ByteArrayInputStream, InputStream}

import cats.implicits._
import cats.effect.Sync
import docspell.common.MimeType
import fs2.Stream
import javax.swing.text.rtf.RTFEditorKit

import scala.util.Try

object RtfExtract {

  val rtfType = MimeType.application("rtf")

  def get(is: InputStream): Either[Throwable, String] =
    Try {
      val kit = new RTFEditorKit()
      val doc = kit.createDefaultDocument()
      kit.read(is, doc, 0)
      doc.getText(0, doc.getLength).trim
    }.toEither

  def get[F[_]: Sync](data: Stream[F, Byte]): F[Either[Throwable, String]] =
    data.compile.to(Array).map(new ByteArrayInputStream(_)).map(get)
}
