/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.webapp

import java.net.URL
import java.util.concurrent.atomic.AtomicReference

import cats.effect._
import cats.implicits._
import fs2.text

import docspell.restserver.{BuildInfo, Config}

import io.circe.syntax._
import org.http4s.HttpRoutes
import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._
import org.http4s.implicits._
import org.log4s._
import yamusca.implicits._
import yamusca.imports._

object TemplateRoutes {
  private[this] val logger = getLogger

  private val textHtml = mediaType"text/html"
  private val appJavascript = mediaType"application/javascript"

  trait InnerRoutes[F[_]] {
    def doc: HttpRoutes[F]
    def app: HttpRoutes[F]
    def serviceWorker: HttpRoutes[F]
  }

  def apply[F[_]: Async](cfg: Config): InnerRoutes[F] = {
    val indexTemplate = memo(
      loadResource(s"/index.html").flatMap(loadTemplate(_))
    )
    val docTemplate = memo(loadResource(s"/doc.html").flatMap(loadTemplate(_)))
    val swTemplate = memo(loadResource(s"/sw.js").flatMap(loadTemplate(_)))

    val dsl = new Http4sDsl[F] {}
    import dsl._
    new InnerRoutes[F] {
      def doc =
        HttpRoutes.of[F] { case GET -> Root =>
          for {
            templ <- docTemplate
            resp <- Ok(
              DocData(cfg).render(templ),
              `Content-Type`(textHtml, Charset.`UTF-8`)
            )
          } yield resp
        }
      def app =
        HttpRoutes.of[F] { case GET -> _ =>
          for {
            templ <- indexTemplate
            resp <- Ok(
              IndexData(cfg).render(templ),
              `Content-Type`(textHtml, Charset.`UTF-8`)
            )
          } yield resp
        }

      def serviceWorker =
        HttpRoutes.of[F] { case GET -> _ =>
          for {
            templ <- swTemplate
            resp <- Ok(
              IndexData(cfg).render(templ),
              `Content-Type`(appJavascript, Charset.`UTF-8`)
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

  def loadUrl[F[_]: Sync](url: URL): F[String] =
    fs2.io
      .readInputStream(Sync[F].delay(url.openStream()), 64 * 1024)
      .through(text.utf8.decode)
      .compile
      .string

  def parseTemplate[F[_]: Sync](str: String): F[Template] =
    Sync[F].pure(mustache.parse(str).leftMap(err => new Exception(err._2))).rethrow

  def loadTemplate[F[_]: Sync](url: URL): F[Template] =
    loadUrl[F](url).flatMap(parseTemplate[F]).map { t =>
      logger.info(s"Compiled template $url")
      t
    }

  case class DocData(swaggerRoot: String, openapiSpec: String)
  object DocData {

    def apply(cfg: Config): DocData =
      DocData(
        cfg.baseUrl.path.asString + "/app/assets" + Webjars.swaggerui,
        s"${cfg.baseUrl.path.asString}/app/assets/${BuildInfo.name}/${BuildInfo.version}/docspell-openapi.yml"
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
    private[this] val uiVersion = 2

    def apply(cfg: Config): IndexData =
      IndexData(
        Flags(cfg, uiVersion),
        chooseUi(cfg),
        Seq(
          cfg.baseUrl.path.asString + "/app/assets" + Webjars.clipboardjs + "/clipboard.min.js",
          s"${cfg.baseUrl.path.asString}/app/assets/docspell-webapp/${BuildInfo.version}/docspell-app.js",
          s"${cfg.baseUrl.path.asString}/app/assets/docspell-webapp/${BuildInfo.version}/docspell-query-opt.js"
        ),
        s"${cfg.baseUrl.path.asString}/app/assets/docspell-webapp/${BuildInfo.version}/favicon",
        s"${cfg.baseUrl.path.asString}/app/assets/docspell-webapp/${BuildInfo.version}/docspell.js",
        Flags(cfg, uiVersion).asJson.spaces2
      )

    private def chooseUi(cfg: Config): Seq[String] =
      Seq(s"${cfg.baseUrl.path.asString}/app/assets/docspell-webapp/${BuildInfo.version}/css/styles.css")

    implicit def yamuscaValueConverter: ValueConverter[IndexData] =
      ValueConverter.deriveConverter[IndexData]
  }

  private def memo[F[_]: Sync, A](fa: => F[A]): F[A] = {
    val ref = new AtomicReference[A]()
    Sync[F].defer {
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
