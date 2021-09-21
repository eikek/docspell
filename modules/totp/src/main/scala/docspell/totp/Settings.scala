/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.totp

import java.util.concurrent.TimeUnit

import scala.concurrent.duration._

import io.circe.generic.semiauto
import io.circe.{Decoder, Encoder}

case class Settings(mac: Mac, passLength: PassLength, duration: FiniteDuration)

object Settings {
  val default =
    Settings(Mac.Sha1, PassLength.Chars6, 30.seconds)

  implicit val jsonEncoder: Encoder[Settings] =
    Codec.jsonEncoder

  implicit val jsonDecoder: Decoder[Settings] =
    Codec.jsonDecoder

  private object Codec {

    implicit val durationEncoder: Encoder[FiniteDuration] =
      Encoder.encodeLong.contramap(_.toSeconds)

    implicit val durationDecoder: Decoder[FiniteDuration] =
      Decoder.decodeLong.map(secs => FiniteDuration(secs, TimeUnit.SECONDS))

    val jsonEncoder: Encoder[Settings] =
      semiauto.deriveEncoder[Settings]

    val jsonDecoder: Decoder[Settings] =
      semiauto.deriveDecoder[Settings]
  }
}
