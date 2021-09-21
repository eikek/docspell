/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.oidc

import io.circe.{Decoder, Json}
import scodec.bits.Bases.Alphabets
import scodec.bits.ByteVector

case class Jwt(header: Json, claims: Json, signature: ByteVector) {

  def claimsAs[A: Decoder]: Either[String, A] =
    claims.as[A].left.map(_.getMessage())
}

object Jwt {
  private[oidc] def create(t: (Json, Json, String)): Jwt =
    Jwt(t._1, t._2, ByteVector.fromValidBase64(t._3, Alphabets.Base64UrlNoPad))
}
