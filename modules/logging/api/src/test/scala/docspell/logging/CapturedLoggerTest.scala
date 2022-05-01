/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import io.circe.{Encoder, Json}
import munit.FunSuite

class CapturedLoggerTest extends FunSuite {

  test("capture data") {
    val logger = TestLogger()
    logger.capture("collective", "demo").capture("id", 1).info("hello")

    assertEquals(
      logger.getEvents.head.data.toMap,
      Map(t("collective" -> "demo"), t("id" -> 1))
    )
  }

  def t[A: Encoder](e: (String, A)): (String, Json) =
    (e._1, Encoder[A].apply(e._2))
}
