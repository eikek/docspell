/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.ws

import docspell.backend.auth.AuthToken
import docspell.common._

sealed trait OutputEvent {
  def forCollective(token: AuthToken): Boolean
  def encode: String
}

object OutputEvent {

  case object KeepAlive extends OutputEvent {
    def forCollective(token: AuthToken): Boolean = true
    def encode: String = "keep-alive"
  }

  final case class ItemProcessed(collective: Ident) extends OutputEvent {
    def forCollective(token: AuthToken): Boolean =
      token.account.collective == collective

    def encode: String =
      "item-processed"
  }

}
