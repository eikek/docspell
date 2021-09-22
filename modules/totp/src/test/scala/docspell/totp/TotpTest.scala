/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.totp

import java.time.Instant

import scala.concurrent.duration._

import cats.Id
import cats.effect._
import cats.effect.unsafe.implicits._

import munit._
import scodec.bits.ByteVector

class TotpTest extends FunSuite {

  val totp = Totp.default
  val key = Key(ByteVector.fromValidBase64("GGFWIWYnHB8F5Dp87iS2HP86k4A="), Mac.Sha1)
  val time = Instant.parse("2021-08-29T18:42:00Z")

  test("generate password") {
    val otp = totp.generate(key, time)
    assertEquals("410352", otp.pass)
  }

  test("generate stream") {
    val otp3 = totp.generateStream[Id](key, time).take(3).compile.toList
    assertEquals(otp3.map(_.pass), List("410352", "557347", "512023"))
  }

  for {
    mac <- Mac.all.toList
    plen <- PassLength.all.toList
  } test(s"generate ${mac.identifier} with ${plen.toInt} characters") {
    val key = Key.generate[IO](mac).unsafeRunSync()
    val totp = Totp(Settings(mac, plen, 30.seconds))
    val otp = totp.generate(key, time)
    assertEquals(otp.pass.length, plen.toInt)
  }

  test("check password at same time") {
    assert(totp.checkPassword(key, OnetimePassword("410352"), time))
  }

  test("check password 15s later") {
    assert(totp.checkPassword(key, OnetimePassword("410352"), time.plusSeconds(15)))
  }

  test("check password 29s later") {
    assert(totp.checkPassword(key, OnetimePassword("410352"), time.plusSeconds(29)))
  }

  test("check password 31s later (too late)") {
    assert(!totp.checkPassword(key, OnetimePassword("410352"), time.plusSeconds(31)))
  }
}
