/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.auth

import cats.effect._
import cats.syntax.option._

import docspell.common._

import munit.CatsEffectSuite
import scodec.bits.ByteVector

class AuthTokenTest extends CatsEffectSuite {

  val user = AccountInfo(
    CollectiveId(1),
    Ident.unsafe("demo"),
    Ident.unsafe("abc-def"),
    Ident.unsafe("demo")
  )
  val john = AccountInfo(
    CollectiveId(1),
    Ident.unsafe("demo"),
    Ident.unsafe("abc-hij"),
    Ident.unsafe("john")
  )
  val secret = ByteVector.fromValidHex("caffee")
  val otherSecret = ByteVector.fromValidHex("16bad")

  test("validate") {
    val token1 =
      AuthToken.user[IO](user, requireSecondFactor = false, secret, None).unsafeRunSync()
    val token2 =
      AuthToken
        .user[IO](user, requireSecondFactor = false, secret, Duration.seconds(10).some)
        .unsafeRunSync()
    assert(token1.validate(secret, Duration.seconds(5)))
    assert(!token1.validate(otherSecret, Duration.seconds(5)))
    assert(!token1.copy(account = john).validate(secret, Duration.seconds(5)))

    assert(token2.validate(secret, Duration.millis(0)))
    assert(
      !token2.copy(valid = Duration.minutes(10).some).validate(secret, Duration.millis(0))
    )
  }

  test("signature") {
    val token1 =
      AuthToken.user[IO](user, requireSecondFactor = false, secret, None).unsafeRunSync()
    val token2 =
      AuthToken
        .user[IO](user, requireSecondFactor = false, secret, Duration.seconds(10).some)
        .unsafeRunSync()

    assert(token1.sigValid(secret))
    assert(token1.sigInvalid(otherSecret))
    assert(token1.copy(valid = Duration.seconds(100).some).sigInvalid(secret))

    assert(token2.sigValid(secret))
    assert(token2.sigInvalid(otherSecret))
  }
}
