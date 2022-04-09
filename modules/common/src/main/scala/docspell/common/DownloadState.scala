/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList

import io.circe.{Decoder, Encoder}

sealed trait DownloadState {
  def name: String
}
object DownloadState {
  case object Forbidden extends DownloadState { val name = "forbidden" }
  case object NotPresent extends DownloadState { val name = "notpresent" }
  case object Preparing extends DownloadState { val name = "preparing" }
  case object Present extends DownloadState { val name = "present" }
  case object Empty extends DownloadState { val name = "empty" }

  val all: NonEmptyList[DownloadState] =
    NonEmptyList.of(Forbidden, NotPresent, Preparing, Present, Empty)

  def fromString(str: String): Either[String, DownloadState] =
    all.find(_.name.equalsIgnoreCase(str)).toRight(s"Unknown download-state: $str")

  def unsafeFromString(str: String): DownloadState =
    fromString(str).fold(sys.error, identity)

  implicit val jsonEncoder: Encoder[DownloadState] =
    Encoder.encodeString.contramap(_.name)

  implicit val jsonDecoder: Decoder[DownloadState] =
    Decoder.decodeString.emap(fromString)
}
