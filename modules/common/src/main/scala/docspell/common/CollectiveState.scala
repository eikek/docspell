/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.{Decoder, Encoder}

sealed trait CollectiveState
object CollectiveState {
  val all = List(Active, ReadOnly, Closed, Blocked)

  /** A normal active collective */
  case object Active extends CollectiveState

  /** A collective may be readonly in cases it is implicitly closed (e.g. no payment).
    * Users can still see there data and download, but have no write access.
    */
  case object ReadOnly extends CollectiveState

  /** A collective that has been explicitely closed. */
  case object Closed extends CollectiveState

  /** A collective blocked by a super user, usually some emergency action.
    */
  case object Blocked extends CollectiveState

  def fromString(s: String): Either[String, CollectiveState] =
    s.toLowerCase match {
      case "active"   => Right(Active)
      case "readonly" => Right(ReadOnly)
      case "closed"   => Right(Closed)
      case "blocked"  => Right(Blocked)
      case _          => Left(s"Unknown state: $s")
    }

  def unsafe(str: String): CollectiveState =
    fromString(str).fold(sys.error, identity)

  def asString(state: CollectiveState): String =
    state match {
      case Active   => "active"
      case Blocked  => "blocked"
      case Closed   => "closed"
      case ReadOnly => "readonly"
    }

  implicit val collectiveStateEncoder: Encoder[CollectiveState] =
    Encoder.encodeString.contramap(CollectiveState.asString)

  implicit val collectiveStateDecoder: Decoder[CollectiveState] =
    Decoder.decodeString.emap(CollectiveState.fromString)

}
