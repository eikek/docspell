/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend

import emil._
import emil.javamail.syntax._
import io.circe.{Decoder, Encoder}

trait MailAddressCodec {

  implicit val jsonEncoder: Encoder[MailAddress] =
    Encoder.encodeString.contramap(_.asUnicodeString)

  implicit val jsonDecoder: Decoder[MailAddress] =
    Decoder.decodeString.emap(MailAddress.parse)
}

object MailAddressCodec extends MailAddressCodec
