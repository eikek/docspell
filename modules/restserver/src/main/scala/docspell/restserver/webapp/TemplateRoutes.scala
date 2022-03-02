/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.webapp

import cats.effect._
import cats.implicits._

import docspell.restserver.{BuildInfo, Config}

import io.circe.syntax._
import org.http4s.HttpRoutes
import org.http4s._
import org.http4s.dsl.Http4sDsl
import org.http4s.headers._
import org.http4s.implicits._
import yamusca.derive._
import yamusca.implicits._
import yamusca.imports._

object TemplateRoutes {

  private val textHtml = mediaType"text/html"
  private val appJavascript = mediaType"application/javascript"

  trait InnerRoutes[F[_]] {
    def doc: HttpRoutes[F]
    def app: HttpRoutes[F]
    def serviceWorker: HttpRoutes[F]
  }

  def apply[F[_]: Async](cfg: Config, templates: Templates[F]): InnerRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._
    new InnerRoutes[F] {
      def doc =
        HttpRoutes.of[F] { case GET -> Root =>
          for {
            docTemplate <- templates.doc
            resp <- Ok(
              DocData().render(docTemplate),
              `Content-Type`(textHtml, Charset.`UTF-8`)
            )
          } yield resp
        }
      def app =
        HttpRoutes.of[F] { case GET -> _ =>
          for {
            indexTemplate <- templates.index
            resp <- Ok(
              IndexData(cfg).render(indexTemplate),
              `Content-Type`(textHtml, Charset.`UTF-8`)
            )
          } yield resp
        }

      def serviceWorker =
        HttpRoutes.of[F] { case GET -> _ =>
          for {
            swTemplate <- templates.serviceWorker
            resp <- Ok(
              IndexData(cfg).render(swTemplate),
              `Content-Type`(appJavascript, Charset.`UTF-8`)
            )
          } yield resp
        }
    }
  }

  case class DocData(swaggerRoot: String, openapiSpec: String)
  object DocData {

    def apply(): DocData =
      DocData(
        "/app/assets" + Webjars.swaggerui,
        s"/app/assets/${BuildInfo.name}/${BuildInfo.version}/docspell-openapi.yml"
      )

    implicit def yamuscaValueConverter: ValueConverter[DocData] =
      deriveValueConverter[DocData]
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
        chooseUi,
        Seq(
          "/app/assets" + Webjars.clipboardjs + "/clipboard.min.js",
          s"/app/assets/docspell-webapp/${BuildInfo.version}/docspell-app.js",
          s"/app/assets/docspell-webapp/${BuildInfo.version}/docspell-query-opt.js"
        ),
        s"/app/assets/docspell-webapp/${BuildInfo.version}/favicon",
        s"/app/assets/docspell-webapp/${BuildInfo.version}/docspell.js",
        Flags(cfg, uiVersion).asJson.spaces2
      )

    private def chooseUi: Seq[String] =
      Seq(s"/app/assets/docspell-webapp/${BuildInfo.version}/css/styles.css")

    implicit def yamuscaValueConverter: ValueConverter[IndexData] =
      deriveValueConverter[IndexData]
  }
}
