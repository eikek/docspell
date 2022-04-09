/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.codec

import docspell.query.{ItemQuery, ItemQueryParser}

import io.circe.{Decoder, Encoder}

// NOTE: this is a copy from ItemQueryJson in restapi! TODO cleanup
trait ItemQueryCodec {

  implicit val itemQueryDecoder: Decoder[ItemQuery] =
    Decoder.decodeString.emap(str => ItemQueryParser.parse(str).left.map(_.render))

  implicit val itemQueryEncoder: Encoder[ItemQuery] =
    Encoder.encodeString.contramap(q =>
      q.raw.getOrElse(ItemQueryParser.unsafeAsString(q.expr))
    )
}

object ItemQueryCodec extends ItemQueryCodec
