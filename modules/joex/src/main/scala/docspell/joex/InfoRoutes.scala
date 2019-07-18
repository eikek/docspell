package docspell.joex

import cats.effect._
import org.http4s._
import org.http4s.HttpRoutes
import org.http4s.dsl.Http4sDsl
import org.http4s.circe.CirceEntityEncoder._

import docspell.joexapi.model._
import docspell.joex.BuildInfo

object InfoRoutes {

  def apply[F[_]: Sync](cfg: Config): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F]{}
    import dsl._
    HttpRoutes.of[F] {
      case GET -> (Root / "version") =>
        Ok(VersionInfo(BuildInfo.version
          , BuildInfo.builtAtMillis
          , BuildInfo.builtAtString
          , BuildInfo.gitHeadCommit.getOrElse("")
          , BuildInfo.gitDescribedVersion.getOrElse("")))
    }
  }
}
