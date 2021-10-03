/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.auth

import docspell.backend.auth.ShareToken
import docspell.common._

import org.http4s._
import org.typelevel.ci.CIString

final case class ShareCookieData(token: ShareToken) {
  def asString: String = token.asString

  def asCookie(baseUrl: LenientUri): ResponseCookie = {
    val sec = baseUrl.scheme.exists(_.endsWith("s"))
    val path = baseUrl.path / "api" / "v1"
    ResponseCookie(
      name = ShareCookieData.cookieName,
      content = asString,
      domain = None,
      path = Some(path.asString),
      httpOnly = true,
      secure = sec,
      maxAge = None,
      expires = None
    )
  }

  def addCookie[F[_]](baseUrl: LenientUri)(
      resp: Response[F]
  ): Response[F] =
    resp.addCookie(asCookie(baseUrl))
}

object ShareCookieData {
  val cookieName = "docspell_share"
  val headerName = "Docspell-Share-Auth"

  def fromCookie[F[_]](req: Request[F]): Option[String] =
    for {
      header <- req.headers.get[headers.Cookie]
      cookie <- header.values.toList.find(_.name == cookieName)
    } yield cookie.content

  def fromHeader[F[_]](req: Request[F]): Option[String] =
    req.headers
      .get(CIString(headerName))
      .map(_.head.value)

  def fromRequest[F[_]](req: Request[F]): Option[String] =
    fromCookie(req).orElse(fromHeader(req))

  def delete(baseUrl: LenientUri): ResponseCookie =
    ResponseCookie(
      name = cookieName,
      content = "",
      domain = None,
      path = Some(baseUrl.path / "api" / "v1").map(_.asString),
      httpOnly = true,
      secure = baseUrl.scheme.exists(_.endsWith("s")),
      maxAge = None,
      expires = None
    )

}
