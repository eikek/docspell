package docspell.restserver.routes

import cats.effect.Sync

import docspell.restapi.model.VersionInfo
import docspell.restserver.BuildInfo

import org.http4s.HttpRoutes
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object InfoRoutes {

  def apply[F[_]: Sync](): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._
    HttpRoutes.of[F] {
      case GET -> (Root / "version") =>
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
}
