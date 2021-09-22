/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.auth

import java.time.Instant

import cats.effect._
import cats.implicits._

import docspell.backend.Common
import docspell.common._

import scodec.bits.ByteVector

case class RememberToken(nowMillis: Long, rememberId: Ident, salt: String, sig: String) {
  def asString = s"$nowMillis-${TokenUtil.b64enc(rememberId.id)}-$salt-$sig"

  def sigValid(key: ByteVector): Boolean = {
    val newSig = TokenUtil.sign(this, key)
    TokenUtil.constTimeEq(sig, newSig)
  }
  def sigInvalid(key: ByteVector): Boolean =
    !sigValid(key)

  def notExpired(validity: Duration): Boolean =
    !isExpired(validity)

  def isExpired(validity: Duration): Boolean = {
    val ends = Instant.ofEpochMilli(nowMillis).plusMillis(validity.millis)
    Instant.now.isAfter(ends)
  }

  def validate(key: ByteVector, validity: Duration): Boolean =
    sigValid(key) && notExpired(validity)
}

object RememberToken {

  def fromString(s: String): Either[String, RememberToken] =
    s.split("\\-", 4) match {
      case Array(ms, as, salt, sig) =>
        for {
          millis <- TokenUtil.asInt(ms).toRight("Cannot read authenticator data")
          rId <- TokenUtil.b64dec(as).toRight("Cannot read authenticator data")
          accId <- Ident.fromString(rId)
        } yield RememberToken(millis, accId, salt, sig)

      case _ =>
        Left("Invalid authenticator")
    }

  def user[F[_]: Sync](rememberId: Ident, key: ByteVector): F[RememberToken] =
    for {
      salt <- Common.genSaltString[F]
      millis = Instant.now.toEpochMilli
      cd = RememberToken(millis, rememberId, salt, "")
      sig = TokenUtil.sign(cd, key)
    } yield cd.copy(sig = sig)

}
