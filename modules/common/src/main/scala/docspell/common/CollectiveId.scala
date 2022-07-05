/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.{Decoder, Encoder}

final class CollectiveId(val value: Long) extends AnyVal {

  override def toString =
    s"CollectiveId($value)"
}

object CollectiveId {
  val unknown: CollectiveId = CollectiveId(-1)

  def apply(n: Long): CollectiveId = new CollectiveId(n)

  implicit val jsonEncoder: Encoder[CollectiveId] =
    Encoder.encodeLong.contramap(_.value)
  implicit val jsonDecoder: Decoder[CollectiveId] =
    Decoder.decodeLong.map(CollectiveId.apply)
}
