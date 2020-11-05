package docspell.restserver.webapp

import java.net.URL
import java.util.concurrent.atomic.AtomicReference

import cats.effect._
import cats.implicits._
import fs2.{Stream, text}

import docspell.restserver.{BuildInfo, Config}

import io.circe.syntax._
import org.http4s.HttpRoutes
import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._
import org.log4s._
import yamusca.implicits._
import yamusca.imports._

object TemplateRoutes {
  private[this] val logger = getLogger

  val `text/html`              = new MediaType("text", "html")
  val `application/javascript` = new MediaType("application", "javascript")

  trait InnerRoutes[F[_]] {
    def doc: HttpRoutes[F]
    def app: HttpRoutes[F]
    def serviceWorker: HttpRoutes[F]
  }

  def apply[F[_]: Effect](blocker: Blocker, cfg: Config)(implicit
      C: ContextShift[F]
  ): InnerRoutes[F] = {
    val indexTemplate = memo(
      loadResource("/index.html").flatMap(loadTemplate(_, blocker))
    )
    val docTemplate = memo(loadResource("/doc.html").flatMap(loadTemplate(_, blocker)))
    val swTemplate  = memo(loadResource("/sw.js").flatMap(loadTemplate(_, blocker)))

    val dsl = new Http4sDsl[F] {}
    import dsl._
    new InnerRoutes[F] {
      def doc =
        HttpRoutes.of[F] { case GET -> Root =>
          for {
            templ <- docTemplate
            resp <- Ok(
              DocData().render(templ),
              `Content-Type`(`text/html`, Charset.`UTF-8`)
            )
          } yield resp
        }
      def app =
        HttpRoutes.of[F] { case GET -> _ =>
          for {
            templ <- indexTemplate
            resp <- Ok(
              IndexData(cfg).render(templ),
              `Content-Type`(`text/html`, Charset.`UTF-8`)
            )
          } yield resp
        }

      def serviceWorker =
        HttpRoutes.of[F] { case GET -> _ =>
          for {
            templ <- swTemplate
            resp <- Ok(
              IndexData(cfg).render(templ),
              `Content-Type`(`application/javascript`, Charset.`UTF-8`)
            )
          } yield resp
        }
    }
  }

  def loadResource[F[_]: Sync](name: String): F[URL] =
    Option(getClass.getResource(name)) match {
      case None =>
        Sync[F].raiseError(new Exception("Unknown resource: " + name))
      case Some(r) =>
        r.pure[F]
    }

  def loadUrl[F[_]: Sync](url: URL, blocker: Blocker)(implicit
      C: ContextShift[F]
  ): F[String] =
    Stream
      .bracket(Sync[F].delay(url.openStream))(in => Sync[F].delay(in.close()))
      .flatMap(in => fs2.io.readInputStream(in.pure[F], 64 * 1024, blocker, false))
      .through(text.utf8Decode)
      .compile
      .fold("")(_ + _)

  def parseTemplate[F[_]: Sync](str: String): F[Template] =
    Sync[F].delay {
      mustache.parse(str) match {
        case Right(t)       => t
        case Left((_, err)) => sys.error(err)
      }
    }

  def loadTemplate[F[_]: Sync](url: URL, blocker: Blocker)(implicit
      C: ContextShift[F]
  ): F[Template] =
    loadUrl[F](url, blocker).flatMap(s => parseTemplate(s)).map { t =>
      logger.info(s"Compiled template $url")
      t
    }

  case class DocData(swaggerRoot: String, openapiSpec: String)
  object DocData {

    def apply(): DocData =
      DocData(
        "/app/assets" + Webjars.swaggerui,
        s"/app/assets/${BuildInfo.name}/${BuildInfo.version}/docspell-openapi.yml"
      )

    implicit def yamuscaValueConverter: ValueConverter[DocData] =
      ValueConverter.deriveConverter[DocData]
  }

  case class IndexData(
      flags: Flags,
      cssUrls: Seq[String],
      jsUrls: Seq[String],
      faviconBase: String,
      appExtraJs: String,
      flagsJson: String
  )

  object IndexData {

    def apply(cfg: Config): IndexData =
      IndexData(
        Flags(cfg),
        Seq(
          "/app/assets" + Webjars.fomanticslimdefault + "/semantic.min.css",
          s"/app/assets/docspell-webapp/${BuildInfo.version}/docspell.css"
        ),
        Seq(
          "/app/assets" + Webjars.clipboardjs + "/clipboard.min.js",
          s"/app/assets/docspell-webapp/${BuildInfo.version}/docspell-app.js"
        ),
        s"/app/assets/docspell-webapp/${BuildInfo.version}/favicon",
        s"/app/assets/docspell-webapp/${BuildInfo.version}/docspell.js",
        Flags(cfg).asJson.spaces2
      )

    implicit def yamuscaValueConverter: ValueConverter[IndexData] =
      ValueConverter.deriveConverter[IndexData]
  }

  private def memo[F[_]: Sync, A](fa: => F[A]): F[A] = {
    val ref = new AtomicReference[A]()
    Sync[F].suspend {
      Option(ref.get) match {
        case Some(a) => a.pure[F]
        case None =>
          fa.map { a =>
            ref.set(a)
            a
          }
      }
    }
  }
}
