package docspell.extract.poi

import java.io.{ByteArrayInputStream, InputStream}

import cats.data.EitherT
import cats.implicits._
import cats.effect.Sync
import org.apache.poi.hssf.extractor.ExcelExtractor
import org.apache.poi.hssf.usermodel.HSSFWorkbook
import org.apache.poi.hwpf.extractor.WordExtractor
import org.apache.poi.xssf.extractor.XSSFExcelExtractor
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import org.apache.poi.xwpf.extractor.XWPFWordExtractor
import org.apache.poi.xwpf.usermodel.XWPFDocument
import fs2.Stream

import scala.util.Try
import docspell.common._
import docspell.files.TikaMimetype

object PoiExtract {

  def get[F[_]: Sync](
      data: Stream[F, Byte],
      hint: MimeTypeHint
  ): F[Either[Throwable, String]] =
    TikaMimetype.detect(data, hint).flatMap(mt => get(data, mt))

  def get[F[_]: Sync](
      data: Stream[F, Byte],
      mime: MimeType
  ): F[Either[Throwable, String]] =
    mime match {
      case PoiType.doc =>
        getDoc(data)
      case PoiType.xls =>
        getXls(data)
      case PoiType.xlsx =>
        getXlsx(data)
      case PoiType.docx =>
        getDocx(data)
      case PoiType.msoffice =>
        EitherT(getDoc[F](data))
          .recoverWith({
            case _ => EitherT(getXls[F](data))
          })
          .value
      case PoiType.ooxml =>
        EitherT(getDocx[F](data))
          .recoverWith({
            case _ => EitherT(getXlsx[F](data))
          })
          .value
      case mt =>
        Sync[F].pure(Left(new Exception(s"Unsupported content: ${mt.asString}")))
    }

  def getDocx(is: InputStream): Either[Throwable, String] =
    Try {
      val xt = new XWPFWordExtractor(new XWPFDocument(is))
      Option(xt.getText).map(_.trim).getOrElse("")
    }.toEither

  def getDoc(is: InputStream): Either[Throwable, String] =
    Try {
      val xt = new WordExtractor(is)
      Option(xt.getText).map(_.trim).getOrElse("")
    }.toEither

  def getXlsx(is: InputStream): Either[Throwable, String] =
    Try {
      val xt = new XSSFExcelExtractor(new XSSFWorkbook(is))
      Option(xt.getText).map(_.trim).getOrElse("")
    }.toEither

  def getXls(is: InputStream): Either[Throwable, String] =
    Try {
      val xt = new ExcelExtractor(new HSSFWorkbook(is))
      Option(xt.getText).map(_.trim).getOrElse("")
    }.toEither

  def getDocx[F[_]: Sync](data: Stream[F, Byte]): F[Either[Throwable, String]] =
    data.compile.to(Array).map(new ByteArrayInputStream(_)).map(getDocx)

  def getDoc[F[_]: Sync](data: Stream[F, Byte]): F[Either[Throwable, String]] =
    data.compile.to(Array).map(new ByteArrayInputStream(_)).map(getDoc)

  def getXlsx[F[_]: Sync](data: Stream[F, Byte]): F[Either[Throwable, String]] =
    data.compile.to(Array).map(new ByteArrayInputStream(_)).map(getXlsx)

  def getXls[F[_]: Sync](data: Stream[F, Byte]): F[Either[Throwable, String]] =
    data.compile.to(Array).map(new ByteArrayInputStream(_)).map(getXls)

}
