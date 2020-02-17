package docspell.files

import cats.implicits._
import cats.effect.Sync
import docspell.common._
import fs2.Stream
import org.apache.tika.config.TikaConfig
import org.apache.tika.metadata.{HttpHeaders, Metadata, TikaMetadataKeys}
import org.apache.tika.mime.MediaType

object TikaMimetype {
  private val tika = new TikaConfig().getDetector

  private def convert(mt: MediaType): MimeType =
    Option(mt)
      .map(_.toString)
      .map(MimeType.parse)
      .flatMap(_.toOption)
      .map(normalize)
      .getOrElse(MimeType.octetStream)

  private def makeMetadata(hint: MimeTypeHint): Metadata = {
    val md = new Metadata
    hint.filename.foreach(md.set(TikaMetadataKeys.RESOURCE_NAME_KEY, _))
    hint.advertised.foreach(md.set(HttpHeaders.CONTENT_TYPE, _))
    md
  }

  private def normalize(in: MimeType): MimeType = in match {
    case MimeType(_, sub) if sub contains "xhtml" =>
      MimeType.html
    case _ => in
  }

  private def fromBytes(bv: Array[Byte], hint: MimeTypeHint): MimeType =
    convert(tika.detect(new java.io.ByteArrayInputStream(bv), makeMetadata(hint)))

  def detect[F[_]: Sync](data: Stream[F, Byte], hint: MimeTypeHint): F[MimeType] =
    data.take(64).compile.toVector.map(bytes => fromBytes(bytes.toArray, hint))

  def resolve[F[_]: Sync](dt: DataType, data: Stream[F, Byte]): F[MimeType] =
    dt match {
      case DataType.Exact(mt)  => mt.pure[F]
      case DataType.Hint(hint) => TikaMimetype.detect(data, hint)
    }
}
