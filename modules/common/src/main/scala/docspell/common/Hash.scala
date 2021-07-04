/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

import java.nio.charset.StandardCharsets

import scodec.bits.ByteVector

final class Hash(bytes: ByteVector) {

  private def digest(name: String): String =
    bytes.digest(name).toHex.toLowerCase

  def sha256: String =
    digest("SHA-256")

  def md5: String =
    digest("MD5")

  def add(str: String): Hash =
    new Hash(bytes ++ ByteVector.view(str.getBytes(StandardCharsets.UTF_8)))

  def add(id: Ident): Hash =
    add(id.id)
}

object Hash {

  def empty: Hash = new Hash(ByteVector.empty)

}
