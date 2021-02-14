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

  def appRoutes[F[_]: Effect](
      blocker: Blocker
  )(implicit CS: ContextShift[F]): HttpRoutes[F] =
    Kleisli {
      case req if req.method == Method.GET =>
        val p = req.pathInfo
        if (p.contains("..") || !suffixes.exists(p.endsWith(_)))
          OptionT.pure(Response.notFound[F])
        else
          StaticFile
            .fromResource(
              s"/META-INF/resources/webjars$p",
              blocker,
              Some(req),
              EnvMode.current.isProd
            )
      case _ =>
        OptionT.none
    }

}
