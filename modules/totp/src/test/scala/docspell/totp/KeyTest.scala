/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.totp

import cats.effect._
import cats.effect.unsafe.implicits._

import docspell.totp.{Key, Mac}

import io.circe.syntax._
import munit._

class KeyTest extends FunSuite {

  test("generate and read in key") {
    val jkey = Key.generateJavaKey(Mac.Sha1)
    val key = Key.fromSecretKey(jkey).fold(sys.error, identity)
    assertEquals(jkey, key.toJavaKey)
  }

  test("generate key") {
    for (mac <- Mac.all.toList) {
      val key = Key.generate[IO](mac).unsafeRunSync()
      assertEquals(key.data.length.toInt * 8, key.mac.keyLengthBits)
    }
  }

  test("encode/decode json") {
    val key = Key.generate[IO](Mac.Sha1).unsafeRunSync()
    val keyJson = key.asJson
    val newKey = keyJson.as[Key].fold(throw _, identity)
    assertEquals(key, newKey)
  }
}
