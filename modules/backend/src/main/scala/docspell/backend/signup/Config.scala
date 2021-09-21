/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.signup

import docspell.common.{Duration, Password}

import io.circe._

case class Config(mode: Config.Mode, newInvitePassword: Password, inviteTime: Duration)

object Config {
  sealed trait Mode { self: Product =>
    final def name: String =
      productPrefix.toLowerCase
  }
  object Mode {

    case object Open extends Mode

    case object Invite extends Mode

    case object Closed extends Mode

    def fromString(str: String): Either[String, Mode] =
      str.toLowerCase match {
        case "open"   => Right(Open)
        case "invite" => Right(Invite)
        case "closed" => Right(Closed)
        case _        => Left(s"Invalid signup mode: $str")
      }
    def unsafe(str: String): Mode =
      fromString(str).fold(sys.error, identity)

    implicit val jsonEncoder: Encoder[Mode] =
      Encoder.encodeString.contramap(_.name)
    implicit val jsonDecoder: Decoder[Mode] =
      Decoder.decodeString.emap(fromString)
  }

  def open: Mode   = Mode.Open
  def invite: Mode = Mode.Invite
  def closed: Mode = Mode.Closed

}
