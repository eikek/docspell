package docspell.extract.odf

import java.io.{ByteArrayInputStream, InputStream}

import scala.util.Try

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.extract.internal.Text

import org.apache.tika.metadata.Metadata
import org.apache.tika.parser.ParseContext
import org.apache.tika.parser.odf.OpenDocumentParser
import org.apache.tika.sax.BodyContentHandler

object OdfExtract {

  def get[F[_]: Sync](data: Stream[F, Byte]): F[Either[Throwable, Text]] =
    data.compile.to(Array).map(new ByteArrayInputStream(_)).map(get)

  def get(is: InputStream) =
    Try {
      val handler  = new BodyContentHandler()
      val pctx     = new ParseContext()
      val meta     = new Metadata()
      val ooparser = new OpenDocumentParser()
      ooparser.parse(is, handler, meta, pctx)
      Text(Option(handler.toString))
    }.toEither

}
