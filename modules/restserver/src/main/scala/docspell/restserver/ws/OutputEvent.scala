/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.ws

import docspell.backend.auth.AuthToken
import docspell.common._

import io.circe._
import io.circe.generic.semiauto.deriveEncoder
import io.circe.syntax._

/** The event that is sent to clients through a websocket connection. All events are
  * encoded as JSON.
  */
sealed trait OutputEvent {
  def forCollective(token: AuthToken): Boolean
  def asJson: Json
  def encode: String =
    asJson.noSpaces
}

object OutputEvent {

  case object KeepAlive extends OutputEvent {
    def forCollective(token: AuthToken): Boolean = true
    def asJson: Json =
      Msg("keep-alive", ()).asJson
  }

  final case class JobSubmitted(group: Ident, task: Ident) extends OutputEvent {
    def forCollective(token: AuthToken): Boolean =
      token.account.collective == group

    def asJson: Json =
      Msg("job-submitted", task).asJson
  }

  final case class JobDone(group: Ident, task: Ident) extends OutputEvent {
    def forCollective(token: AuthToken): Boolean =
      token.account.collective == group

    def asJson: Json =
      Msg("job-done", task).asJson
  }

  final case class JobsWaiting(collective: Ident, count: Int) extends OutputEvent {
    def forCollective(token: AuthToken): Boolean =
      token.account.collective == collective

    def asJson: Json =
      Msg("jobs-waiting", count).asJson
  }

  private case class Msg[A](tag: String, content: A)
  private object Msg {
    @scala.annotation.nowarn
    implicit def jsonEncoder[A: Encoder]: Encoder[Msg[A]] =
      deriveEncoder
  }
}
