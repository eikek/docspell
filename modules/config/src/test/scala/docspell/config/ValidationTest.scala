/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.config

import munit.FunSuite

class ValidationTest extends FunSuite {

  test("thread value through validations") {
    val v1 = Validation[Int](n => Validation.valid(n + 1))
    assertEquals(v1.validOrThrow(0), 1)
    assertEquals(Validation.of(v1, v1, v1).validOrThrow(0), 3)
  }

  test("fail if there is at least one error") {
    val v1 = Validation[Int](n => Validation.valid(n + 1))
    val v2 = Validation.error[Int]("error")
    assertEquals(Validation.of(v1, v2).run(0), Validation.invalid("error"))
    assertEquals(Validation.of(v2, v1).run(0), Validation.invalid("error"))
  }
}
