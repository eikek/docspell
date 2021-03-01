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
import org.http4s.util.CaseInsensitiveString
import org.http4s.util.Writer
import org.log4s._
import yamusca.implicits._
import yamusca.imports._

object TemplateRoutes {
  private[this] val logger = getLogger

  val `text/html`              = new MediaType("text", "html")
  val `application/javascript` = new MediaType("application", "javascript")

  val ui2Header = CaseInsensitiveString("Docspell-Ui2")

  case class UiVersion(version: Int) extends Header.Parsed {
    val key = UiVersion
    def renderValue(writer: Writer): writer.type =
      writer.append(version)
  }
  object UiVersion extends HeaderKey.Singleton {
    val default = UiVersion(2)

    def get[F[_]](req: Request[F]): UiVersion =
      req.headers.get(UiVersion).getOrElse(UiVersion.default)

    type HeaderT = UiVersion
    val name = CaseInsensitiveString("Docspell-Ui")
    override def parse(s: String): ParseResult[UiVersion] =
      Either
        .catchNonFatal(s.trim.toInt)
        .leftMap(ex => ParseFailure("Invalid int header", ex.getMessage))
        .map(UiVersion.apply)

    override def matchHeader(h: Header): Option[UiVersion] =
      if (h.name == name) parse(h.value).toOption
      else None
  }

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
        HttpRoutes.of[F] { case req @ GET -> _ =>
          for {
            templ <- indexTemplate
            uiv = UiVersion.get(req).version
            resp <- Ok(
              IndexData(cfg, uiv).render(templ),
              `Content-Type`(`text/html`, Charset.`UTF-8`)
            )
          } yield resp
        }

      def serviceWorker =
        HttpRoutes.of[F] { case req @ GET -> _ =>
          for {
            templ <- swTemplate
            uiv = UiVersion.get(req).version
            resp <- Ok(
              IndexData(cfg, uiv).render(templ),
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

    def apply(cfg: Config, uiVersion: Int): IndexData =
      IndexData(
        Flags(cfg, uiVersion),
        chooseUi(uiVersion),
        Seq(
          "/app/assets" + Webjars.clipboardjs + "/clipboard.min.js",
          s"/app/assets/docspell-webapp/${BuildInfo.version}/docspell-app.js",
          s"/app/assets/docspell-webapp/${BuildInfo.version}/docspell-query-opt.js"
        ),
        s"/app/assets/docspell-webapp/${BuildInfo.version}/favicon",
        s"/app/assets/docspell-webapp/${BuildInfo.version}/docspell.js",
        Flags(cfg, uiVersion).asJson.spaces2
      )

    private def chooseUi(uiVersion: Int): Seq[String] =
      if (uiVersion == 2)
        Seq(s"/app/assets/docspell-webapp/${BuildInfo.version}/css/styles.css")
      else
        Seq(
          "/app/assets" + Webjars.fomanticslimdefault + "/semantic.min.css",
          s"/app/assets/docspell-webapp/${BuildInfo.version}/docspell.css"
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
