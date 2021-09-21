/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.webapp

import cats.data.Kleisli
import cats.data.OptionT
import cats.effect._

import docspell.common._

import org.http4s._

object WebjarRoutes {

  private[this] val suffixes = List(
    ".js",
    ".css",
    ".html",
    ".json",
    ".jpg",
    ".png",
    ".eot",
    ".woff",
    ".woff2",
    ".svg",
    ".otf",
    ".ttf",
    ".yml",
    ".xml"
  )

  def appRoutes[F[_]: Async]: HttpRoutes[F] =
    Kleisli {
      case req if req.method == Method.GET =>
        val p             = req.pathInfo.renderString
        val last          = req.pathInfo.segments.lastOption.map(_.encoded).getOrElse("")
        val containsColon = req.pathInfo.segments.exists(_.encoded.contains(".."))
        if (containsColon || !suffixes.exists(last.endsWith(_)))
          OptionT.pure(Response.notFound[F])
        else
          StaticFile
            .fromResource(
              s"/META-INF/resources/webjars$p",
              Some(req),
              EnvMode.current.isProd
            )
      case _ =>
        OptionT.none
    }

}
