package docspell.extract.pdfbox

import java.io.InputStream
import java.nio.file.Path

import cats.implicits._
import cats.effect.Sync
import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.text.PDFTextStripper

import scala.util.{Try, Using}
import fs2.Stream

object PdfboxExtract {

  def get[F[_]: Sync](data: Stream[F, Byte]): F[Either[Throwable, String]] =
    data.compile.to(Array).map(bytes => Using(PDDocument.load(bytes))(readText).toEither.flatten)

  def get(is: InputStream): Either[Throwable, String] =
    Using(PDDocument.load(is))(readText).toEither.flatten

  def get(inFile: Path): Either[Throwable, String] =
    Using(PDDocument.load(inFile.toFile))(readText).toEither.flatten

  private def readText(doc: PDDocument): Either[Throwable, String] =
    Try {
      val stripper = new PDFTextStripper()
      stripper.setAddMoreFormatting(true)
      stripper.setLineSeparator("\n")
      stripper.getText(doc).trim // trim here already
    }.toEither
}
