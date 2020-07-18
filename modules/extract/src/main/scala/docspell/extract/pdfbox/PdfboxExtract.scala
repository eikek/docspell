package docspell.extract.pdfbox

import java.io.InputStream
import java.nio.file.Path

import scala.util.{Try, Using}

import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import docspell.common.Timestamp
import docspell.extract.internal.Text

import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.text.PDFTextStripper

object PdfboxExtract {

  def getTextAndMetaData[F[_]: Sync](
      data: Stream[F, Byte]
  ): F[Either[Throwable, (Text, Option[PdfMetaData])]] =
    data.compile
      .to(Array)
      .map(bytes =>
        Using(PDDocument.load(bytes)) { doc =>
          for {
            txt <- readText(doc)
            md  <- readMetaData(doc)
          } yield (txt, Some(md).filter(_.nonEmpty))
        }.toEither.flatten
      )

  def getText[F[_]: Sync](data: Stream[F, Byte]): F[Either[Throwable, Text]] =
    data.compile
      .to(Array)
      .map(bytes => Using(PDDocument.load(bytes))(readText).toEither.flatten)

  def getText(is: InputStream): Either[Throwable, Text] =
    Using(PDDocument.load(is))(readText).toEither.flatten

  def getText(inFile: Path): Either[Throwable, Text] =
    Using(PDDocument.load(inFile.toFile))(readText).toEither.flatten

  private def readText(doc: PDDocument): Either[Throwable, Text] =
    Try {
      val stripper = new PDFTextStripper()
      stripper.setAddMoreFormatting(true)
      stripper.setLineSeparator("\n")
      Text(Option(stripper.getText(doc)))
    }.toEither

  def getMetaData[F[_]: Sync](data: Stream[F, Byte]): F[Either[Throwable, PdfMetaData]] =
    data.compile
      .to(Array)
      .map(bytes => Using(PDDocument.load(bytes))(readMetaData).toEither.flatten)

  def getMetaData(is: InputStream): Either[Throwable, PdfMetaData] =
    Using(PDDocument.load(is))(readMetaData).toEither.flatten

  def getMetaData(inFile: Path): Either[Throwable, PdfMetaData] =
    Using(PDDocument.load(inFile.toFile))(readMetaData).toEither.flatten

  private def readMetaData(doc: PDDocument): Either[Throwable, PdfMetaData] =
    Try {
      def mkValue(s: String) =
        Option(s).map(_.trim).filter(_.nonEmpty)

      val info = doc.getDocumentInformation
      PdfMetaData(
        mkValue(info.getTitle),
        mkValue(info.getAuthor),
        mkValue(info.getSubject),
        mkValue(info.getKeywords),
        mkValue(info.getCreator),
        Option(info.getCreationDate).map(c => Timestamp(c.toInstant))
      )
    }.toEither
}
