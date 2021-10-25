/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.auth

import cats.effect._
import cats.implicits._

import docspell.backend.Common
import docspell.common.{Ident, Timestamp}

import scodec.bits.ByteVector

/** Can be used as an authenticator to access data behind a share. */
final case class ShareToken(created: Timestamp, id: Ident, salt: String, sig: String) {
  def asString = s"${created.toMillis}-${TokenUtil.b64enc(id.id)}-$salt-$sig"

  def sigValid(key: ByteVector): Boolean = {
    val newSig = TokenUtil.sign(this, key)
    TokenUtil.constTimeEq(sig, newSig)
  }
  def sigInvalid(key: ByteVector): Boolean =
    !sigValid(key)
}

object ShareToken {

  def fromString(s: String): Either[String, ShareToken] =
    s.split("-", 4) match {
      case Array(ms, id, salt, sig) =>
        for {
          created <- ms.toLongOption.toRight("Invalid timestamp")
          idStr <- TokenUtil.b64dec(id).toRight("Cannot read authenticator data")
          shareId <- Ident.fromString(idStr)
        } yield ShareToken(Timestamp.ofMillis(created), shareId, salt, sig)

      case _ =>
        Left("Invalid authenticator")
    }

  def create[F[_]: Sync](shareId: Ident, key: ByteVector): F[ShareToken] =
    for {
      now <- Timestamp.current[F]
      salt <- Common.genSaltString[F]
      cd = ShareToken(now, shareId, salt, "")
      sig = TokenUtil.sign(cd, key)
    } yield cd.copy(sig = sig)

}
