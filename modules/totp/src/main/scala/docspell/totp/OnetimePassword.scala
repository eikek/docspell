/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.totp

import io.circe.{Decoder, Encoder}

final class OnetimePassword(val pass: String) extends AnyVal {
  override def toString: String = "***"
}

object OnetimePassword {

  def apply(pass: String): OnetimePassword =
    new OnetimePassword(pass)

  def unapply(op: OnetimePassword): Option[String] =
    Some(op.pass)

  implicit val jsonEncoder: Encoder[OnetimePassword] =
    Encoder.encodeString.contramap(_.pass)

  implicit val jsonDecoder: Decoder[OnetimePassword] =
    Decoder.decodeString.map(OnetimePassword.apply)
}
