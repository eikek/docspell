package docspell.restserver.http4s

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.backend.ops._

import bitpeace.FileMeta
import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.ETag.EntityTag
import org.http4s.headers._

object BinaryUtil {

  def withResponseHeaders[F[_]: Sync](dsl: Http4sDsl[F], resp: F[Response[F]])(
      data: OItemSearch.BinaryData[F]
  ): F[Response[F]] = {
    import dsl._

    val mt             = MediaType.unsafeParse(data.meta.mimetype.asString)
    val ctype          = `Content-Type`(mt)
    val cntLen: Header = `Content-Length`.unsafeFromLong(data.meta.length)
    val eTag: Header   = ETag(data.meta.checksum)
    val disp: Header =
      `Content-Disposition`("inline", Map("filename" -> data.name.getOrElse("")))

    resp.map(r =>
      if (r.status == NotModified) r.withHeaders(ctype, eTag, disp)
      else r.withHeaders(ctype, cntLen, eTag, disp)
    )
  }

  def makeByteResp[F[_]: Sync](
      dsl: Http4sDsl[F]
  )(data: OItemSearch.BinaryData[F]): F[Response[F]] = {
    import dsl._
    withResponseHeaders(dsl, Ok(data.data.take(data.meta.length)))(data)
  }

  def matchETag[F[_]](
      fileData: Option[FileMeta],
      noneMatch: Option[NonEmptyList[EntityTag]]
  ): Boolean =
    (fileData, noneMatch) match {
      case (Some(meta), Some(nm)) =>
        meta.checksum == nm.head.tag
      case _ =>
        false
    }

}
