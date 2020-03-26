package docspell.restserver.routes

import bitpeace.FileMeta
import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._
import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._
import org.http4s.headers.ETag.EntityTag
import org.http4s.circe.CirceEntityEncoder._
import docspell.backend.BackendApp
import docspell.backend.auth.AuthToken
import docspell.backend.ops.OItem
import docspell.common.Ident
import docspell.restapi.model._
import docspell.restserver.conv.Conversions
import docspell.restserver.webapp.Webjars

object AttachmentRoutes {

  def apply[F[_]: Effect](backend: BackendApp[F], user: AuthToken): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    def withResponseHeaders(
        resp: F[Response[F]]
    )(data: OItem.BinaryData[F]): F[Response[F]] = {
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

    def makeByteResp(data: OItem.BinaryData[F]): F[Response[F]] =
      withResponseHeaders(Ok(data.data.take(data.meta.length)))(data)

    HttpRoutes.of {
      case HEAD -> Root / Ident(id) =>
        for {
          fileData <- backend.item.findAttachment(id, user.account.collective)
          resp <- fileData
            .map(data => withResponseHeaders(Ok())(data))
            .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case req @ GET -> Root / Ident(id) =>
        for {
          fileData <- backend.item.findAttachment(id, user.account.collective)
          inm     = req.headers.get(`If-None-Match`).flatMap(_.tags)
          matches = matchETag(fileData.map(_.meta), inm)
          resp <- fileData
            .map { data =>
              if (matches) withResponseHeaders(NotModified())(data)
              else makeByteResp(data)
            }
            .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case HEAD -> Root / Ident(id) / "original" =>
        for {
          fileData <- backend.item.findAttachmentSource(id, user.account.collective)
          resp <- fileData
            .map(data => withResponseHeaders(Ok())(data))
            .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case req @ GET -> Root / Ident(id) / "original" =>
        for {
          fileData <- backend.item.findAttachmentSource(id, user.account.collective)
          inm     = req.headers.get(`If-None-Match`).flatMap(_.tags)
          matches = matchETag(fileData.map(_.meta), inm)
          resp <- fileData
            .map { data =>
              if (matches) withResponseHeaders(NotModified())(data)
              else makeByteResp(data)
            }
            .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case HEAD -> Root / Ident(id) / "archive" =>
        for {
          fileData <- backend.item.findAttachmentArchive(id, user.account.collective)
          resp <- fileData
            .map(data => withResponseHeaders(Ok())(data))
            .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case req @ GET -> Root / Ident(id) / "archive" =>
        for {
          fileData <- backend.item.findAttachmentArchive(id, user.account.collective)
          inm     = req.headers.get(`If-None-Match`).flatMap(_.tags)
          matches = matchETag(fileData.map(_.meta), inm)
          resp <- fileData
            .map { data =>
              if (matches) withResponseHeaders(NotModified())(data)
              else makeByteResp(data)
            }
            .getOrElse(NotFound(BasicResult(false, "Not found")))
        } yield resp

      case GET -> Root / Ident(id) / "view" =>
        // this route exists to provide a stable url
        // it redirects currently to viewerjs
        val attachUrl = s"/api/v1/sec/attachment/${id.id}"
        val path      = s"/app/assets${Webjars.viewerjs}/ViewerJS/index.html#$attachUrl"
        SeeOther(Location(Uri(path = path)))

      case GET -> Root / Ident(id) / "meta" =>
        for {
          rm <- backend.item.findAttachmentMeta(id, user.account.collective)
          md = rm.map(Conversions.mkAttachmentMeta)
          resp <- md.map(Ok(_)).getOrElse(NotFound(BasicResult(false, "Not found.")))
        } yield resp
    }
  }

  private def matchETag[F[_]](
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
