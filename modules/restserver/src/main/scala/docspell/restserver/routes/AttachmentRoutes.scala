package docspell.restserver.routes

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OItem
import docspell.common.Ident
import org.http4s.{Header, HttpRoutes, MediaType, Response}
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._
import org.http4s.circe.CirceEntityEncoder._
import docspell.restapi.model._
import docspell.restserver.Config
import docspell.restserver.conv.Conversions
import org.http4s.headers.ETag.EntityTag

object AttachmentRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], cfg: Config, user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F]{}
    import dsl._

    def makeByteResp(data: OItem.AttachmentData[F]): F[Response[F]] = {
      val mt = MediaType.unsafeParse(data.meta.mimetype.asString)
      val cntLen: Header = `Content-Length`.unsafeFromLong(data.meta.length)
      val eTag: Header = ETag(data.meta.checksum)
      val disp: Header = `Content-Disposition`("inline", Map("filename" -> data.ra.name.getOrElse("")))
      Ok(data.data.take(data.meta.length)).
        map(r => r.withContentType(`Content-Type`(mt)).
          withHeaders(cntLen, eTag, disp))
    }

    HttpRoutes.of {
      case req @ GET -> Root / Ident(id) =>
        for {
          fileData <- backend.item.findAttachment(id, user.account.collective)
          inm      = req.headers.get(`If-None-Match`).flatMap(_.tags)
          matches  = matchETag(fileData, inm)
          resp     <- if (matches) NotModified()
                      else fileData.map(makeByteResp).getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case GET -> Root / Ident(id) / "meta" =>
        for {
          rm  <- backend.item.findAttachmentMeta(id, user.account.collective)
          md   = rm.map(Conversions.mkAttachmentMeta)
          resp <- md.map(Ok(_)).getOrElse(NotFound(BasicResult(false, "Not found.")))
        } yield resp
    }
  }

  private def matchETag[F[_]]( fileData: Option[OItem.AttachmentData[F]]
                             , noneMatch: Option[NonEmptyList[EntityTag]]): Boolean =
    (fileData, noneMatch) match {
      case (Some(fd), Some(nm)) =>
        fd.meta.checksum == nm.head.tag
      case _ =>
        false
    }

}
