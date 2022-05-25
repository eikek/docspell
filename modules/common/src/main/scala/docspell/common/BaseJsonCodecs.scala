/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.time.Instant

import io.circe._
import scodec.bits.ByteVector

trait BaseJsonCodecs {

  implicit val encodeInstantEpoch: Encoder[Instant] =
    Encoder.encodeJavaLong.contramap(_.toEpochMilli)

  implicit val decodeInstantEpoch: Decoder[Instant] =
    Decoder.decodeLong.map(Instant.ofEpochMilli)

  implicit val byteVectorEncoder: Encoder[ByteVector] =
    Encoder.encodeString.contramap(_.toBase64)

  implicit val byteVectorDecoder: Decoder[ByteVector] =
    Decoder.decodeString.emap(ByteVector.fromBase64Descriptive(_))
}

object BaseJsonCodecs extends BaseJsonCodecs
