/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.util

import munit.FunSuite
import scodec.bits.ByteVector

class SignUtilTest extends FunSuite {

  private val key = ByteVector.fromValidHex("caffee")

  test("create and validate") {
    val sig = SignUtil.signString("hello", key)
    assert(SignUtil.isEqual(sig, SignUtil.signString("hello", key)))
  }
}
