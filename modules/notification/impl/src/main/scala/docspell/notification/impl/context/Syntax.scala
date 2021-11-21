/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl.context

import docspell.notification.api.Event

object Syntax {

  implicit final class EventOps(ev: Event) {

    def itemUrl: Option[String] =
      ev.baseUrl.map(_ / "app" / "item").map(_.asString)
  }
}
