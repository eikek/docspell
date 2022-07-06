/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.auth

import cats.implicits._

import docspell.common.util.SignUtil

import scodec.bits._

private[auth] object TokenUtil {
  private val utf8 = java.nio.charset.StandardCharsets.UTF_8

  def sign(cd: RememberToken, key: ByteVector): String = {
    val raw = cd.nowMillis.toString + cd.rememberId.id + cd.salt
    signRaw(raw, key)
  }

  def sign(cd: AuthToken, key: ByteVector): String = {
    val raw =
      cd.nowMillis.toString + cd.account.asString + cd.requireSecondFactor + cd.salt + cd.valid
        .map(_.seconds.toString)
        .getOrElse("")
    signRaw(raw, key)
  }

  def sign(sd: ShareToken, key: ByteVector): String = {
    val raw = s"${sd.created.toMillis}${sd.id.id}${sd.salt}"
    signRaw(raw, key)
  }

  private def signRaw(data: String, key: ByteVector): String =
    SignUtil.signString(data, key).toBase64

  def b64enc(s: String): String =
    ByteVector.view(s.getBytes(utf8)).toBase64

  def b64dec(s: String): Option[String] =
    ByteVector.fromBase64(s).flatMap(_.decodeUtf8.toOption)

  def asInt(s: String): Option[Long] =
    Either.catchNonFatal(s.toLong).toOption

  def constTimeEq(s1: String, s2: String): Boolean =
    s1.zip(s2)
      .foldLeft(true) { case (r, (c1, c2)) => r & c1 == c2 } & s1.length == s2.length
}
