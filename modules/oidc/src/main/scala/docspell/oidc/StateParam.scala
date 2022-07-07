/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.oidc

import cats.effect._
import cats.syntax.all._

import docspell.common.util.{Random, SignUtil}

import scodec.bits.Bases.Alphabets
import scodec.bits.ByteVector

final case class StateParam(value: String, sig: ByteVector) {
  def asString: String =
    s"$value$$${sig.toBase64UrlNoPad}"

  def isValid(key: ByteVector): Boolean = {
    val actual = SignUtil.signString(value, key)
    SignUtil.isEqual(actual, sig)
  }
}

object StateParam {

  def generate[F[_]: Sync](key: ByteVector): F[StateParam] =
    Random[F].string(8).map { v =>
      val sig = SignUtil.signString(v, key)
      StateParam(v, sig)
    }

  def fromString(str: String, key: ByteVector): Either[String, StateParam] =
    str.split('$') match {
      case Array(v, sig) =>
        ByteVector
          .fromBase64Descriptive(sig, Alphabets.Base64UrlNoPad)
          .map(s => StateParam(v, s))
          .filterOrElse(_.isValid(key), s"Invalid signature in state param: $str")

      case _ =>
        Left(s"Invalid state parameter: $str")
    }

  def isValidStateParam(state: String, key: ByteVector) =
    fromString(state, key).isRight
}
