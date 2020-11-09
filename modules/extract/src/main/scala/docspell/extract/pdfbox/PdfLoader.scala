package docspell.extract.pdfbox

import cats.effect._
import cats.implicits._
import fs2.Stream

import org.apache.pdfbox.pdmodel.PDDocument

object PdfLoader {

  private def readBytes1[F[_]: Sync](bytes: Array[Byte]): F[PDDocument] =
    Sync[F].delay(PDDocument.load(bytes))

  private def closePDDocument[F[_]: Sync](pd: PDDocument): F[Unit] =
    Sync[F].delay(pd.close())

  def withDocumentBytes[F[_]: Sync, A](pdf: Array[Byte])(f: PDDocument => F[A]): F[A] =
    Sync[F].bracket(readBytes1(pdf))(f)(pd => closePDDocument(pd))

  def withDocumentStream[F[_]: Sync, A](pdf: Stream[F, Byte])(
      f: PDDocument => F[A]
  ): F[A] =
    pdf.compile.to(Array).flatMap(bytes => withDocumentBytes(bytes)(f))
}
