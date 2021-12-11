/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import java.util

import com.vladsch.flexmark.ext.gfm.strikethrough.StrikethroughExtension
import com.vladsch.flexmark.ext.tables.TablesExtension
import com.vladsch.flexmark.html.HtmlRenderer
import com.vladsch.flexmark.parser.Parser
import com.vladsch.flexmark.util.data.{DataKey, MutableDataSet}

object Markdown {

  def toHtml(md: String): String = {
    val p = createParser()
    val r = createRenderer()
    val doc = p.parse(md)
    r.render(doc).trim
  }

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
