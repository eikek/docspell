/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.convert.flexmark

import java.io.{InputStream, InputStreamReader}
import java.nio.charset.Charset
import java.util

import scala.util.Try

import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import docspell.common._

import com.vladsch.flexmark.ext.gfm.strikethrough.StrikethroughExtension
import com.vladsch.flexmark.ext.tables.TablesExtension
import com.vladsch.flexmark.html.HtmlRenderer
import com.vladsch.flexmark.parser.Parser
import com.vladsch.flexmark.util.data.{DataKey, MutableDataSet}

object Markdown {

  def toHtml(
      is: InputStream,
      cfg: MarkdownConfig,
      cs: Charset
  ): Either[Throwable, String] = {
    val p = createParser()
    val r = createRenderer()
    Try {
      val reader = new InputStreamReader(is, cs)
      val doc    = p.parseReader(reader)
      wrapHtml(r.render(doc), cfg)
    }.toEither
  }

  def toHtml(md: String, cfg: MarkdownConfig): String = {
    val p   = createParser()
    val r   = createRenderer()
    val doc = p.parse(md)
    wrapHtml(r.render(doc), cfg)
  }

  def toHtml[F[_]: Sync](
      data: Stream[F, Byte],
      cfg: MarkdownConfig,
      cs: Charset
  ): F[String] =
    data.through(Binary.decode(cs)).compile.foldMonoid.map(str => toHtml(str, cfg))

  private def wrapHtml(body: String, cfg: MarkdownConfig): String =
    s"""<!DOCTYPE html>
       |<html>
       |<head>
       |<meta charset="utf-8"/>
       |<style>
       |${cfg.internalCss}
       |</style>
       |</head>
       |<body>
       |$body
       |</body>
       |</html>
       |""".stripMargin

  private def createParser(): Parser = {
    val opts = new MutableDataSet()
    opts.set(
      Parser.EXTENSIONS.asInstanceOf[DataKey[util.Collection[_]]],
      util.Arrays.asList(TablesExtension.create(), StrikethroughExtension.create())
    );

    Parser.builder(opts).build()
  }

  private def createRenderer(): HtmlRenderer = {
    val opts = new MutableDataSet()
    HtmlRenderer.builder(opts).build()
  }
}
