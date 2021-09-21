/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
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
