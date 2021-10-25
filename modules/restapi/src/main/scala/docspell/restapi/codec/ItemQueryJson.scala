/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restapi.codec

import docspell.query.{ItemQuery, ItemQueryParser}

import io.circe.{Decoder, Encoder}

trait ItemQueryJson {

  implicit val itemQueryDecoder: Decoder[ItemQuery] =
    Decoder.decodeString.emap(str => ItemQueryParser.parse(str).left.map(_.render))

  implicit val itemQueryEncoder: Encoder[ItemQuery] =
    Encoder.encodeString.contramap(q =>
      q.raw.getOrElse(ItemQueryParser.unsafeAsString(q.expr))
    )
}

object ItemQueryJson extends ItemQueryJson
