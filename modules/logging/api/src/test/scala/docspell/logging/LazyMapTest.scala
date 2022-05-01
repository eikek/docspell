/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import java.util.concurrent.atomic.AtomicInteger

import munit.FunSuite

class LazyMapTest extends FunSuite {
  test("updated value lazy") {
    val counter = new AtomicInteger(0)
    val lm = LazyMap
      .empty[String, Int]
      .updated("test", produce(counter, 1))

    assertEquals(counter.get(), 0)
    assertEquals(lm.toMap("test"), 1)
    assertEquals(counter.get(), 1)

    for (_ <- 1 to 10) {
      assertEquals(lm.toMap("test"), 1)
      assertEquals(counter.get(), 1)
    }
  }

  test("get doesn't evaluate value") {
    val counter = new AtomicInteger(0)
    val lm = LazyMap
      .empty[String, Int]
      .updated("test", produce(counter, 1))

    val v = lm.get("test")
    assert(v.isDefined)
    assertEquals(counter.get(), 0)

    assertEquals(v.get(), 1)
    assertEquals(counter.get(), 1)

    assertEquals(v.get(), 1)
    assertEquals(counter.get(), 1)
  }

  def produce(counter: AtomicInteger, n: Int): Int = {
    counter.incrementAndGet()
    n
  }
}
