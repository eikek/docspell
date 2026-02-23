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

  test("override addons.configs via env vars") {
    val cfg = EnvConfig.loadFrom(
      Map(
        "DOCSPELL_JOEX_ADDONS_CONFIGS_0_NAME" -> "postgres-addon",
        "DOCSPELL_JOEX_ADDONS_CONFIGS_0_ENABLED" -> "true",
        "DOCSPELL_JOEX_ADDONS_CONFIGS_0_ENVS_0_NAME" -> "PG_HOST",
        "DOCSPELL_JOEX_ADDONS_CONFIGS_0_ENVS_0_VALUE" -> "localhost"
      ).view
    )
    assertEquals(cfg.getString("docspell.joex.addons.configs.0.name"), "postgres-addon")
    assertEquals(cfg.getBoolean("docspell.joex.addons.configs.0.enabled"), true)
    assertEquals(cfg.getString("docspell.joex.addons.configs.0.envs.0.name"), "PG_HOST")
    assertEquals(cfg.getString("docspell.joex.addons.configs.0.envs.0.value"), "localhost")
  }
}
