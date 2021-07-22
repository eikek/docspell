/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.restserver.http4s

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.restserver.Config

import org.http4s._
import org.http4s.headers._
import org.typelevel.ci.CIString

/** Obtain information about the client by inspecting the request.
  */
object ClientRequestInfo {

  def getBaseUrl[F[_]](cfg: Config, req: Request[F]): LenientUri =
    if (cfg.baseUrl.isLocal) getBaseUrl(req, cfg.bind.port).getOrElse(cfg.baseUrl)
    else cfg.baseUrl

  private def getBaseUrl[F[_]](req: Request[F], serverPort: Int): Option[LenientUri] =
    for {
      scheme <- NonEmptyList.fromList(getProtocol(req).toList)
      host   <- getHostname(req)
      port     = xForwardedPort(req).getOrElse(serverPort)
      hostPort = if (port == 80 || port == 443) host else s"${host}:${port}"
    } yield LenientUri(scheme, Some(hostPort), LenientUri.EmptyPath, None, None)

  def getHostname[F[_]](req: Request[F]): Option[String] =
    xForwardedHost(req)
      .orElse(xForwardedFor(req))
      .orElse(host(req))

  def getProtocol[F[_]](req: Request[F]): Option[String] =
    xForwardedProto(req).orElse(clientConnectionProto(req))

  private def host[F[_]](req: Request[F]): Option[String] =
    req.headers.get[Host].map(_.host)

  private def xForwardedFor[F[_]](req: Request[F]): Option[String] =
    req.headers
      .get[`X-Forwarded-For`]
      .flatMap(_.values.head)
      .map(_.toInetAddress)
      .flatMap(inet => Option(inet.getHostName).orElse(Option(inet.getHostAddress)))

  private def xForwardedHost[F[_]](req: Request[F]): Option[String] =
    req.headers
      .get(CIString("X-Forwarded-Host"))
      .map(_.head.value)

  private def xForwardedProto[F[_]](req: Request[F]): Option[String] =
    req.headers
      .get(CIString("X-Forwarded-Proto"))
      .map(_.head.value)

  private def clientConnectionProto[F[_]](req: Request[F]): Option[String] =
    req.isSecure.map {
      case true  => "https"
      case false => "http"
    }

  private def xForwardedPort[F[_]](req: Request[F]): Option[Int] =
    req.headers
      .get(CIString("X-Forwarded-Port"))
      .map(_.head.value)
      .flatMap(str => Either.catchNonFatal(str.toInt).toOption)

}
