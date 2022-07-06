/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.util

import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

import scodec.bits.ByteVector

object SignUtil {
  private val utf8 = java.nio.charset.StandardCharsets.UTF_8

  private val macAlgo = "HmacSHA1"

  private def getMac(key: ByteVector) = {
    val mac = Mac.getInstance(macAlgo)
    mac.init(new SecretKeySpec(key.toArray, macAlgo))
    mac
  }

  def signString(data: String, key: ByteVector): ByteVector = {
    val mac = getMac(key)
    ByteVector.view(mac.doFinal(data.getBytes(utf8)))
  }

  def signBytes(data: ByteVector, key: ByteVector): ByteVector = {
    val mac = getMac(key)
    ByteVector.view(mac.doFinal(data.toArray))
  }

  def isEqual(sig1: ByteVector, sig2: ByteVector): Boolean =
    sig1
      .zipWith(sig2)((b1, b2) => (b1 - b2).toByte)
      .foldLeft(true)(_ && _ == 0) && sig1.length == sig2.length
}
