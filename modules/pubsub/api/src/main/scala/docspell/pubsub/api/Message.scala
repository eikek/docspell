/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.api

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder, Json}

final case class Message[A](head: MessageHead, body: A) {}

object Message {
  implicit val jsonDecoderJson: Decoder[Message[Json]] =
    deriveDecoder[Message[Json]]

  implicit val jsonEncoderJson: Encoder[Message[Json]] =
    deriveEncoder[Message[Json]]

  implicit def jsonDecoder[A](implicit da: Decoder[A]): Decoder[Message[A]] =
    jsonDecoderJson.emap(mj =>
      da.decodeJson(mj.body).map(b => mj.copy(body = b)).left.map(_.message)
    )

  implicit def jsonEncoder[A](implicit ea: Encoder[A]): Encoder[Message[A]] =
    jsonEncoderJson.contramap(m => m.copy(body = ea(m.body)))
}
