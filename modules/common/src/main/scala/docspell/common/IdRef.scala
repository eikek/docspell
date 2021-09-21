/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.Order

import io.circe._
import io.circe.generic.semiauto._

case class IdRef(id: Ident, name: String) {}

object IdRef {

  implicit val jsonEncoder: Encoder[IdRef] =
    deriveEncoder[IdRef]
  implicit val jsonDecoder: Decoder[IdRef] =
    deriveDecoder[IdRef]

  implicit val order: Order[IdRef] =
    Order.by(_.id)
}
