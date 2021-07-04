/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

import java.time.Instant

import io.circe._

object BaseJsonCodecs {

  implicit val encodeInstantEpoch: Encoder[Instant] =
    Encoder.encodeJavaLong.contramap(_.toEpochMilli)

  implicit val decodeInstantEpoch: Decoder[Instant] =
    Decoder.decodeLong.map(Instant.ofEpochMilli)

}
