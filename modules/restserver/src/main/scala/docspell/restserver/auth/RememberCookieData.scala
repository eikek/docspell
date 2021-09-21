/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.auth

import docspell.backend.auth._
import docspell.common._

import org.http4s._

case class RememberCookieData(token: RememberToken) {
  def asString: String = token.asString

  def asCookie(config: Login.RememberMe, baseUrl: LenientUri): ResponseCookie = {
    val sec  = baseUrl.scheme.exists(_.endsWith("s"))
    val path = baseUrl.path / "api" / "v1"
    ResponseCookie(
      name = RememberCookieData.cookieName,
      content = asString,
      domain = None,
      path = Some(path.asString),
      httpOnly = true,
      secure = sec,
      maxAge = Some(config.valid.seconds)
    )
  }

  def addCookie[F[_]](cfg: Login.RememberMe, baseUrl: LenientUri)(
      resp: Response[F]
  ): Response[F] =
    resp.addCookie(asCookie(cfg, baseUrl))

}
object RememberCookieData {
  val cookieName = "docspell_remember"

  def fromCookie[F[_]](req: Request[F]): Option[String] =
    for {
      header <- req.headers.get[headers.Cookie]
      cookie <- header.values.toList.find(_.name == cookieName)
    } yield cookie.content

  def delete(baseUrl: LenientUri): ResponseCookie =
    ResponseCookie(
      cookieName,
      "",
      domain = None,
      path = Some(baseUrl.path / "api" / "v1").map(_.asString),
      httpOnly = true,
      secure = baseUrl.scheme.exists(_.endsWith("s")),
      maxAge = Some(-1)
    )

}
