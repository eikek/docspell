/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.config

import munit.FunSuite

class EnvConfigTest extends FunSuite {

  test("convert underscores") {
    assertEquals(EnvConfig.envToProp("A_B_C"), "a.b.c")
    assertEquals(EnvConfig.envToProp("A_B__C"), "a.b-c")
    assertEquals(EnvConfig.envToProp("AA_BB__CC___D"), "aa.bb-cc_d")
  }

  test("insert docspell keys") {
    val cfg = EnvConfig.loadFrom(
      Map(
        "DOCSPELL_SERVER_APP__NAME" -> "Hello!",
        "DOCSPELL_JOEX_BIND_PORT" -> "1234"
      ).view
    )

    assertEquals(cfg.getString("docspell.server.app-name"), "Hello!")
    assertEquals(cfg.getInt("docspell.joex.bind.port"), 1234)
  }

  test("find default values from reference.conf") {
    val cfg = EnvConfig.loadFrom(
      Map(
        "DOCSPELL_SERVER_APP__NAME" -> "Hello!",
        "DOCSPELL_JOEX_BIND_PORT" -> "1234"
      ).view
    )
    assertEquals(cfg.getInt("docspell.server.bind.port"), 7880)
  }

  test("discard non docspell keys") {
    val cfg = EnvConfig.loadFrom(Map("A_B_C" -> "12").view)
    assert(!cfg.hasPath("a.b.c"))
  }
}
