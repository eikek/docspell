/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.auth

import docspell.backend.auth._
import docspell.common.AccountId
import docspell.common.LenientUri

import org.http4s._
import org.typelevel.ci.CIString

case class CookieData(auth: AuthToken) {
  def accountId: AccountId = auth.account
  def asString: String     = auth.asString

  def asCookie(baseUrl: LenientUri): ResponseCookie = {
    val sec  = baseUrl.scheme.exists(_.endsWith("s"))
    val path = baseUrl.path / "api" / "v1" / "sec"
    ResponseCookie(
      CookieData.cookieName,
      asString,
      domain = None,
      path = Some(path.asString),
      httpOnly = true,
      secure = sec
    )
  }

  def addCookie[F[_]](baseUrl: LenientUri)(resp: Response[F]): Response[F] =
    resp.addCookie(asCookie(baseUrl))

}
object CookieData {
  val cookieName = "docspell_auth"
  val headerName = "X-Docspell-Auth"

  def authenticator[F[_]](r: Request[F]): Either[String, String] =
    fromCookie(r).orElse(fromHeader(r))

  def fromCookie[F[_]](req: Request[F]): Either[String, String] =
    for {
      header <- req.headers.get[headers.Cookie].toRight("Cookie parsing error")
      cookie <-
        header.values.toList
          .find(_.name == cookieName)
          .toRight("Couldn't find the authcookie")
    } yield cookie.content

  def fromHeader[F[_]](req: Request[F]): Either[String, String] =
    req.headers
      .get(CIString(headerName))
      .map(_.head.value)
      .toRight("Couldn't find an authenticator")

  def deleteCookie(baseUrl: LenientUri): ResponseCookie =
    ResponseCookie(
      cookieName,
      "",
      domain = None,
      path = Some(baseUrl.path / "api" / "v1" / "sec").map(_.asString),
      httpOnly = true,
      secure = baseUrl.scheme.exists(_.endsWith("s")),
      maxAge = Some(-1)
    )

}
