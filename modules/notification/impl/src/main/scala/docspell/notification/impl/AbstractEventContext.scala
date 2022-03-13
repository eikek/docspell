/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import docspell.notification.api.{EventContext, EventMessage}

import yamusca.circe._
import yamusca.implicits._
import yamusca.imports._

abstract class AbstractEventContext extends EventContext {

  def titleTemplate: Either[String, Template]

  def bodyTemplate: Either[String, Template]

  def render(template: Template): String =
    asJson.render(template).trim()

  def renderHtml(template: Template): String =
    Markdown.toHtml(render(template))

  lazy val defaultMessage: Either[String, EventMessage] =
    for {
      title <- titleTemplate.map(render)
      body <- bodyTemplate.map(render)
    } yield EventMessage(title, body)

  lazy val defaultMessageHtml: Either[String, EventMessage] =
    for {
      title <- titleTemplate.map(renderHtml)
      body <- bodyTemplate.map(renderHtml)
    } yield EventMessage(title, body)

  lazy val defaultBoth: Either[String, String] =
    for {
      tt <- titleTemplate
      tb <- bodyTemplate
    } yield render(
      AbstractEventContext.concat(
        tt,
        AbstractEventContext.sepTemplate,
        tb
      )
    )

  lazy val defaultBothHtml: Either[String, String] =
    for {
      tt <- titleTemplate
      tb <- bodyTemplate
    } yield renderHtml(
      AbstractEventContext.concat(
        tt,
        AbstractEventContext.sepTemplate,
        tb
      )
    )
}

object AbstractEventContext {
  private val sepTemplate: Template = mustache": "

  private def concat(t1: Template, ts: Template*): Template =
    Template(ts.foldLeft(t1.els)((res, el) => res ++ el.els))
}
