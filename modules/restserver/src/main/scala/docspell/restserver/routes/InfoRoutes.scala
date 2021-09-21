/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.restapi.model.VersionInfo
import docspell.restserver.{BuildInfo, Config}

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object InfoRoutes {

  def apply[F[_]: Sync](): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._
    HttpRoutes.of[F] { case GET -> (Root / "version") =>
      Ok(
        VersionInfo(
          BuildInfo.version,
          BuildInfo.builtAtMillis,
          BuildInfo.builtAtString,
          BuildInfo.gitHeadCommit.getOrElse(""),
          BuildInfo.gitDescribedVersion.getOrElse("")
        )
      )
    }
  }

  def admin[F[_]: Sync](cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._
    HttpRoutes.of[F] { case GET -> Root / "system" =>
      JvmInfo.create[F](cfg.appId).flatMap(Ok(_))
    }

  }
}
