/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import docspell.notification.api.EventContext

import yamusca.circe._
import yamusca.implicits._
import yamusca.imports._

abstract class AbstractEventContext extends EventContext {

  def titleTemplate: Template

  def bodyTemplate: Template

  def render(template: Template): String =
    asJson.render(template).trim()

  def renderHtml(template: Template): String =
    Markdown.toHtml(render(template))

  lazy val defaultTitle: String =
    render(titleTemplate)

  lazy val defaultTitleHtml: String =
    renderHtml(titleTemplate)

  lazy val defaultBody: String =
    render(bodyTemplate)

  lazy val defaultBodyHtml: String =
    renderHtml(bodyTemplate)

  lazy val defaultBoth: String =
    render(
      AbstractEventContext.concat(
        titleTemplate,
        AbstractEventContext.sepTemplate,
        bodyTemplate
      )
    )

  lazy val defaultBothHtml: String =
    renderHtml(
      AbstractEventContext.concat(
        titleTemplate,
        AbstractEventContext.sepTemplate,
        bodyTemplate
      )
    )
}

object AbstractEventContext {
  private val sepTemplate: Template = mustache": "

  private def concat(t1: Template, ts: Template*): Template =
    Template(ts.foldLeft(t1.els)((res, el) => res ++ el.els))
}
