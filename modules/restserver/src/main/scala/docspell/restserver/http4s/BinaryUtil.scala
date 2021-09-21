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

import docspell.backend.ops._
import docspell.store.records.RFileMeta

import org.http4s._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers.ETag.EntityTag
import org.http4s.headers._
import org.typelevel.ci.CIString

object BinaryUtil {

  def withResponseHeaders[F[_]: Sync](dsl: Http4sDsl[F], resp: F[Response[F]])(
      data: OItemSearch.BinaryData[F]
  ): F[Response[F]] = {
    import dsl._

    val mt     = MediaType.unsafeParse(data.meta.mimetype.asString)
    val ctype  = `Content-Type`(mt)
    val cntLen = `Content-Length`.unsafeFromLong(data.meta.length.bytes)
    val eTag   = ETag(data.meta.checksum.toHex)
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
      fileData: Option[RFileMeta],
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
