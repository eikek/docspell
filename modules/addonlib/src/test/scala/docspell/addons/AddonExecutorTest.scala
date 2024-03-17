/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.effect._
import cats.syntax.all._

import docspell.addons.out.AddonOutput
import docspell.common.UrlReader
import docspell.common.bc.{BackendCommand, ItemAction}
import docspell.logging.{Level, TestLoggingConfig}

import munit._

class AddonExecutorTest extends CatsEffectSuite with Fixtures with TestLoggingConfig {
  val logger = docspell.logging.getLogger[IO]

  override def docspellLogConfig =
    super.docspellLogConfig.copy(minimumLevel = Level.Error)

  tempDir.test("select docker if Dockerfile exists") { dir =>
    for {
      _ <- files.createFile(dir / "Dockerfile")
      cfg = testExecutorConfig(
        RunnerType.Docker,
        RunnerType.NixFlake,
        RunnerType.Trivial
      )
      meta = dummyAddonMeta.copy(runner = None)
      r <- AddonExecutor.selectRunner[IO](cfg, meta, dir)
      _ = assertEquals(r.runnerType, List(RunnerType.Docker))
    } yield ()
  }

  tempDir.test("select nix-flake if flake.nix exists") { dir =>
    for {
      _ <- files.createFile(dir / "flake.nix")
      cfg = testExecutorConfig(
        RunnerType.Docker,
        RunnerType.NixFlake,
        RunnerType.Trivial
      )
      meta = dummyAddonMeta.copy(runner = None)
      r <- AddonExecutor.selectRunner[IO](cfg, meta, dir)
      _ = assertEquals(r.runnerType, List(RunnerType.NixFlake))
    } yield ()
  }

  tempDir.test("select nix-flake and docker") { dir =>
    for {
      _ <- files.createFile(dir / "flake.nix")
      _ <- files.createFile(dir / "Dockerfile")
      cfg = testExecutorConfig(
        RunnerType.Docker,
        RunnerType.NixFlake,
        RunnerType.Trivial
      )
      meta = dummyAddonMeta.copy(runner = None)
      r <- AddonExecutor.selectRunner[IO](cfg, meta, dir)
      _ = assertEquals(r.runnerType, List(RunnerType.Docker, RunnerType.NixFlake))
    } yield ()
  }

  tempDir.test("fail early if configured so") { dir =>
    val cfg = testExecutorConfig(RunnerType.Trivial).copy(failFast = true)
    val exec = AddonExecutor[IO](cfg, UrlReader.defaultReader).execute(logger)
    val testOut = AddonOutput(commands =
      List(
        BackendCommand.item(id("xyz-item"), List(ItemAction.AddTags(Set("tag1", "tag2"))))
      )
    )
    val result = createInputEnv(
      dir,
      AddonGenerator.failingAddon("addon1"),
      AddonGenerator.successAddon("addon2", output = testOut.some)
    ).use(exec.run)
    result.map { res =>
      assert(res.isFailure)
      assert(res.pure)
      assertEquals(res.addonResult, AddonResult.executionError(1))
      assertEquals(res.addonResults.size, 1)
    }
  }

  tempDir.test("do not stop after failing addons") { dir =>
    val cfg = testExecutorConfig(RunnerType.Trivial).copy(failFast = false)
    val exec = AddonExecutor[IO](cfg, UrlReader.defaultReader).execute(logger)
    val testOut = AddonOutput(commands =
      List(
        BackendCommand.item(id("xyz-item"), List(ItemAction.AddTags(Set("tag1", "tag2"))))
      )
    )
    val result = createInputEnv(
      dir,
      AddonGenerator.failingAddon("addon1"),
      AddonGenerator.successAddon("addon2", output = testOut.some)
    ).use(exec.run)
    result.map { res =>
      assert(res.isFailure)
      assert(res.pure)
      assertEquals(res.addonResult, AddonResult.executionError(1))
      assertEquals(res.addonResults.size, 2)
      assertEquals(res.addonResults.head, AddonResult.executionError(1))
      assertEquals(res.addonResults(1), AddonResult.success(testOut))
    }
  }

  tempDir.test("combine outputs") { dir =>
    val cfg = testExecutorConfig(RunnerType.Trivial).copy(failFast = false)
    val exec = AddonExecutor[IO](cfg, UrlReader.defaultReader).execute(logger)
    val testOut1 = AddonOutput(commands =
      List(
        BackendCommand.item(id("xyz-item"), List(ItemAction.AddTags(Set("tag1", "tag2"))))
      )
    )
    val testOut2 = AddonOutput(commands =
      List(
        BackendCommand.item(id("xyz-item"), List(ItemAction.SetName("new item name")))
      )
    )
    val result = createInputEnv(
      dir,
      AddonGenerator.successAddon("addon1", output = testOut1.some),
      AddonGenerator.successAddon("addon2", output = testOut2.some)
    ).use(exec.run)
    result.map { res =>
      assert(res.isSuccess)
      assert(res.pure)
      assertEquals(res.addonResult, AddonResult.success(testOut1.combine(testOut2)))
      assertEquals(res.addonResults.size, 2)
      assertEquals(res.addonResults.head, AddonResult.success(testOut1))
      assertEquals(res.addonResults(1), AddonResult.success(testOut2))
    }
  }

  test("AddonExecutionResult's monoid") {
    assert(
      AddonExecutionResult.executionResultMonoid
        .combine(
          AddonExecutionResult.empty,
          AddonExecutionResult(Nil, pure = true)
        )
        .pure
    )
  }
}
