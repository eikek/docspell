/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

final case class EventMessage(title: String, body: String)

object EventMessage {
  val empty: EventMessage = EventMessage("", "")
}
