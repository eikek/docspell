/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.http4s

import cats.data.NonEmptyList
import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.ops.OItemSearch.{AttachmentPreviewData, BinaryData}
import docspell.backend.ops._
import docspell.restapi.model.BasicResult
import docspell.restserver.http4s.{QueryParam => QP}
import docspell.store.file.FileMetadata

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.ETag.EntityTag
import org.http4s.headers._
import org.typelevel.ci.CIString

object BinaryUtil {

  def respond[F[_]: Async](dsl: Http4sDsl[F], req: Request[F])(
      fileData: Option[BinaryData[F]]
  ): F[Response[F]] = {
    import dsl._

    val inm = req.headers.get[`If-None-Match`].flatMap(_.tags)
    val matches = BinaryUtil.matchETag(fileData.map(_.meta), inm)
    fileData
      .map { data =>
        if (matches) withResponseHeaders(dsl, NotModified())(data)
        else makeByteResp(dsl)(data)
      }
      .getOrElse(NotFound(BasicResult(success = false, "Not found")))
  }

  def respondHead[F[_]: Async](dsl: Http4sDsl[F])(
      fileData: Option[BinaryData[F]]
  ): F[Response[F]] = {
    import dsl._

    fileData
      .map(data => withResponseHeaders(dsl, Ok())(data))
      .getOrElse(NotFound(BasicResult(success = false, "Not found")))
  }

  def respondPreview[F[_]: Async](dsl: Http4sDsl[F], req: Request[F])(
      fileData: Option[AttachmentPreviewData[F]]
  ): F[Response[F]] = {
    import dsl._
    def notFound =
      NotFound(BasicResult(success = false, "Not found"))

    QP.WithFallback.unapply(req.multiParams) match {
      case Some(bool) =>
        val fallback = bool.getOrElse(false)
        val inm = req.headers.get[`If-None-Match`].flatMap(_.tags)
        val matches = matchETag(fileData.map(_.meta), inm)

        fileData
          .map { data =>
            if (matches) withResponseHeaders(dsl, NotModified())(data)
            else makeByteResp(dsl)(data)
          }
          .getOrElse(
            if (fallback) BinaryUtil.noPreview(req.some).getOrElseF(notFound)
            else notFound
          )

      case None =>
        BadRequest(BasicResult(success = false, "Invalid query parameter 'withFallback'"))
    }
  }

  def respondPreviewHead[F[_]: Async](
      dsl: Http4sDsl[F]
  )(fileData: Option[AttachmentPreviewData[F]]): F[Response[F]] = {
    import dsl._
    fileData
      .map(data => withResponseHeaders(dsl, Ok())(data))
      .getOrElse(NotFound(BasicResult(success = false, "Not found")))
  }

  def withResponseHeaders[F[_]: Sync](dsl: Http4sDsl[F], resp: F[Response[F]])(
      data: OItemSearch.BinaryData[F]
  ): F[Response[F]] = {
    import dsl._

    val mt = MediaType.unsafeParse(data.meta.mimetype.asString)
    val ctype = `Content-Type`(mt)
    val cntLen = `Content-Length`.unsafeFromLong(data.meta.length.bytes)
    val eTag = ETag(data.meta.checksum.toHex)
    val disp =
      `Content-Disposition`(
        "inline",
        Map(CIString("filename") -> data.name.getOrElse(""))
      )

    resp.map(r =>
      if (r.status == NotModified) r.withHeaders(ctype, eTag, disp)
      else r.withHeaders(ctype, cntLen, eTag, disp)
    )
  }

  def makeByteResp[F[_]: Sync](
      dsl: Http4sDsl[F]
  )(data: OItemSearch.BinaryData[F]): F[Response[F]] = {
    import dsl._
    withResponseHeaders(dsl, Ok(data.data.take(data.meta.length.bytes)))(data)
  }

  def matchETag[F[_]](
      fileData: Option[FileMetadata],
      noneMatch: Option[NonEmptyList[EntityTag]]
  ): Boolean =
    (fileData, noneMatch) match {
      case (Some(meta), Some(nm)) =>
        meta.checksum.toHex == nm.head.tag
      case _ =>
        false
    }

  def noPreview[F[_]: Async](req: Option[Request[F]]): OptionT[F, Response[F]] =
    StaticFile.fromResource(
      name = "/docspell/restserver/no-preview.svg",
      req = req,
      preferGzipped = true,
      classloader = getClass.getClassLoader().some
    )

}
