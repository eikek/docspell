/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.webapp

import java.net.URL

import cats.effect._
import cats.effect.unsafe.implicits._
import cats.implicits._
import fs2.text

import yamusca.imports._

trait Templates[F[_]] {
  def index: F[Template]
  def doc: F[Template]
  def serviceWorker: F[Template]
}

object Templates {

  def apply[F[_]: Sync]: Templates[F] =
    new Templates[F] {
      def index = Templates.indexTemplate.pure[F]
      def doc = Templates.docTemplate.pure[F]
      def serviceWorker = Templates.swTemplate.pure[F]
    }

  private lazy val indexTemplate = fromResource[IO]("/index.html").unsafeRunSync()
  private lazy val docTemplate = fromResource[IO]("/doc.html").unsafeRunSync()
  private lazy val swTemplate = fromResource[IO]("/sw.js").unsafeRunSync()

  def fromResource[F[_]: Sync](path: String): F[Template] =
    loadResource[F](path).flatMap(loadTemplate[F](_))

  private def loadResource[F[_]: Sync](name: String): F[URL] =
    Option(getClass.getResource(name)) match {
      case None =>
        Sync[F].raiseError(new Exception("Unknown resource: " + name))
      case Some(r) =>
        r.pure[F]
    }

  private def loadUrl[F[_]: Sync](url: URL): F[String] =
    fs2.io
      .readInputStream(Sync[F].delay(url.openStream()), 64 * 1024)
      .through(text.utf8.decode)
      .compile
      .string

  private def parseTemplate[F[_]: Sync](str: String): F[Template] =
    Sync[F].pure(mustache.parse(str).leftMap(err => new Exception(err._2))).rethrow

  private def loadTemplate[F[_]: Sync](url: URL): F[Template] = {
    val logger = docspell.logging.getLogger[F]
    loadUrl[F](url).flatMap(parseTemplate[F]).flatMap { t =>
      logger.info(s"Compiled template $url") *> t.pure[F]
    }
  }
}
