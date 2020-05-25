package docspell.extract.pdfbox

import java.io.InputStream
import java.nio.file.Path

import cats.implicits._
import cats.effect.Sync
import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.text.PDFTextStripper

import scala.util.{Try, Using}
import fs2.Stream
import docspell.extract.internal.Text

object PdfboxExtract {

  def get[F[_]: Sync](data: Stream[F, Byte]): F[Either[Throwable, Text]] =
    data.compile
      .to(Array)
      .map(bytes => Using(PDDocument.load(bytes))(readText).toEither.flatten)

  def get(is: InputStream): Either[Throwable, Text] =
    Using(PDDocument.load(is))(readText).toEither.flatten

  def get(inFile: Path): Either[Throwable, Text] =
    Using(PDDocument.load(inFile.toFile))(readText).toEither.flatten

  private def readText(doc: PDDocument): Either[Throwable, Text] =
    Try {
      val stripper = new PDFTextStripper()
      stripper.setAddMoreFormatting(true)
      stripper.setLineSeparator("\n")
      Text(Option(stripper.getText(doc)))
    }.toEither
}
