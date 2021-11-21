/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.{Decoder, Encoder}

final case class ItemQueryString(query: String) {
  def isEmpty: Boolean =
    query.isEmpty
}

object ItemQueryString {

  def apply(qs: Option[String]): ItemQueryString =
    ItemQueryString(qs.getOrElse(""))

  implicit val jsonEncoder: Encoder[ItemQueryString] =
    Encoder.encodeString.contramap(_.query)
  implicit val jsonDecoder: Decoder[ItemQueryString] =
    Decoder.decodeString.map(ItemQueryString.apply)
}
