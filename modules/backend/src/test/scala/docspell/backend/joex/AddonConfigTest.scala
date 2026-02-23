/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.joex

import docspell.common.exec.Env
import docspell.config.Implicits._

import pureconfig.ConfigSource
import pureconfig.generic.auto._

import munit.FunSuite

class AddonConfigTest extends FunSuite {

  test("parse AddonConfig from HOCON with value only") {
    val config = ConfigSource.string("""
        |name = "my-addon"
        |enabled = true
        |envs = [
        |  { name = "FOO", value = "bar" }
        |]
        |""".stripMargin)
    val result = config.at("").load[AddonConfig]
    assert(result.isRight, clue = result.left.map(_.toString))
    val cfg = result.toOption.get
    assertEquals(cfg.name, "my-addon")
    assertEquals(cfg.enabled, true)
    assertEquals(cfg.envs.size, 1)
    assertEquals(cfg.envs.head.name, "FOO")
    assertEquals(cfg.envs.head.value, Some("bar"))
    assertEquals(cfg.envs.head.valueFrom, None)
  }

  test("parse AddonConfig from HOCON with valueFrom only") {
    val config = ConfigSource.string("""
        |name = "my-addon"
        |enabled = true
        |envs = [
        |  {
        |    name = "SECRET"
        |    value-from = { env = "DS_SECRET", optional = true }
        |  }
        |]
        |""".stripMargin)
    val result = config.at("").load[AddonConfig]
    assert(result.isRight, clue = result.left.map(_.toString))
    val cfg = result.toOption.get
    assertEquals(cfg.envs.size, 1)
    assertEquals(cfg.envs.head.name, "SECRET")
    assertEquals(cfg.envs.head.value, None)
    assertEquals(cfg.envs.head.valueFrom, Some(AddonEnvVarFrom(env = Some("DS_SECRET"), optional = true)))
  }

  test("parse AddonConfig with both value and valueFrom") {
    val config = ConfigSource.string("""
        |name = "my-addon"
        |envs = [
        |  {
        |    name = "MIXED"
        |    value = "direct"
        |    value-from = { env = "DS_MIXED", optional = false }
        |  }
        |]
        |""".stripMargin)
    val result = config.at("").load[AddonConfig]
    assert(result.isRight, clue = result.left.map(_.toString))
    val cfg = result.toOption.get
    assertEquals(cfg.envs.head.value, Some("direct"))
    assertEquals(cfg.envs.head.valueFrom, Some(AddonEnvVarFrom(env = Some("DS_MIXED"), optional = false)))
  }

  test("parse AddonEnvConfig with empty addonConfigs") {
    val config = ConfigSource.string("""
        |working-dir = "/tmp/work"
        |cache-dir = "/tmp/cache"
        |executor-config {
        |  runner = "trivial"
        |  run-timeout = "5 minutes"
        |  fail-fast = true
        |  nspawn = { enabled = false, sudo-binary = "sudo", nspawn-binary = "nspawn", container-wait = "100 millis" }
        |  nix-runner = { nix-binary = "nix", build-timeout = "5 minutes" }
        |  docker-runner = { docker-binary = "docker", build-timeout = "5 minutes" }
        |}
        |""".stripMargin)
    val result = config.at("").load[AddonEnvConfig]
    assert(result.isRight, clue = result.left.map(_.toString))
    val cfg = result.toOption.get
    assertEquals(cfg.configs, Nil)
  }

  test("parse AddonEnvConfig with non-empty addonConfigs") {
    val config = ConfigSource.string("""
        |working-dir = "/tmp/work"
        |cache-dir = "/tmp/cache"
        |executor-config {
        |  runner = "trivial"
        |  run-timeout = "5 minutes"
        |  fail-fast = true
        |  nspawn = { enabled = false, sudo-binary = "sudo", nspawn-binary = "nspawn", container-wait = "100 millis" }
        |  nix-runner = { nix-binary = "nix", build-timeout = "5 minutes" }
        |  docker-runner = { docker-binary = "docker", build-timeout = "5 minutes" }
        |}
        |configs = [
        |  {
        |    name = "postgres-addon"
        |    enabled = true
        |    envs = [
        |      { name = "PG_HOST", value = "localhost" }
        |    ]
        |  }
        |]
        |""".stripMargin)
    val result = config.at("").load[AddonEnvConfig]
    assert(result.isRight, clue = result.left.map(_.toString))
    val cfg = result.toOption.get
    assertEquals(cfg.configs.size, 1)
    assertEquals(cfg.configs.head.name, "postgres-addon")
    assertEquals(cfg.configs.head.envs.head.name, "PG_HOST")
    assertEquals(cfg.configs.head.envs.head.value, Some("localhost"))
  }

  test("AddonEnvVar.resolve with value") {
    val ev = AddonEnvVar(name = "FOO", value = Some("bar"))
    assertEquals(ev.resolve, Some("FOO" -> "bar"))
  }

  test("AddonEnvVar.resolve with valueFrom, optional=true, env unset") {
    val ev = AddonEnvVar(
      name = "SECRET",
      valueFrom = Some(AddonEnvVarFrom(env = Some("DOCSPELL_ADDON_TEST_UNLIKELY_12345"), optional = true))
    )
    assertEquals(ev.resolve, None)
  }

  test("AddonEnvVar.resolve with valueFrom, optional=false, env unset") {
    val ev = AddonEnvVar(
      name = "REQUIRED",
      valueFrom = Some(AddonEnvVarFrom(env = Some("DOCSPELL_ADDON_TEST_UNLIKELY_67890"), optional = false))
    )
    assertEquals(ev.resolve, Some("REQUIRED" -> ""))
  }

  test("AddonConfig.toEnv when disabled") {
    val cfg = AddonConfig(name = "x", enabled = false, envs = List(AddonEnvVar("A", value = Some("a"))))
    assertEquals(cfg.toEnv, Env.empty)
  }

  test("AddonConfig.toEnv when enabled") {
    val cfg = AddonConfig(
      name = "x",
      enabled = true,
      envs = List(
        AddonEnvVar("A", value = Some("a")),
        AddonEnvVar("B", value = Some("b"))
      )
    )
    val env = cfg.toEnv
    assertEquals(env.values.get("A"), Some("a"))
    assertEquals(env.values.get("B"), Some("b"))
  }
}
