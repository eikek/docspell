/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.effect._

import docspell.logging.{Level, TestLoggingConfig}

import munit._

class AddonExecutorTest extends CatsEffectSuite with Fixtures with TestLoggingConfig {
  val logger = docspell.logging.getLogger[IO]

  override def docspellLogConfig =
    super.docspellLogConfig.copy(minimumLevel = Level.Trace)

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
}
