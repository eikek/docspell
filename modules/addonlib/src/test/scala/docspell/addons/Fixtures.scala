/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.effect._
import cats.syntax.all._
import fs2.io.file.{Files, Path, PosixPermissions}

import docspell.addons.AddonExecutorConfig._
import docspell.addons.AddonMeta._
import docspell.addons.AddonTriggerType._
import docspell.common.{Duration, LenientUri}
import docspell.logging.TestLoggingConfig

import munit.CatsEffectSuite

trait Fixtures extends TestLoggingConfig { self: CatsEffectSuite =>

  val files: Files[IO] = Files[IO]

  val dummyAddonUrl =
    LenientUri.fromJava(getClass.getResource("/docspell-dummy-addon-master.zip"))

  val dummyAddonMeta =
    AddonMeta(
      meta =
        AddonMeta.Meta("dummy-addon", "2.9", "Some dummy addon only for testing.\n".some),
      triggers = Some(
        Set(Scheduled, FinalProcessItem, FinalReprocessItem)
      ),
      None,
      runner = Runner(
        nix = NixRunner(true).some,
        docker = DockerRunner(
          enable = true,
          image = None,
          build = "Dockerfile".some
        ).some,
        trivial = TrivialRunner(true, "src/addon.sh").some
      ).some,
      options = Options(networking = true, collectOutput = true).some
    )

  def baseTempDir: Path =
    Path(s"/tmp/target/test-temp")

  val tempDir =
    ResourceFixture[Path](
      Resource.eval(Files[IO].createDirectories(baseTempDir)) *>
        Files[IO]
          .tempDirectory(baseTempDir.some, "run-", PosixPermissions.fromOctal("777"))
    )

  def testExecutorConfig(
      runner: RunnerType,
      runners: RunnerType*
  ): AddonExecutorConfig = {
    val nspawn = NSpawn(true, "sudo", "systemd-nspawn", Duration.millis(100))
    AddonExecutorConfig(
      runner :: runners.toList,
      Duration.minutes(2),
      nspawn,
      NixConfig("nix", Duration.minutes(2)),
      DockerConfig("docker", Duration.minutes(2))
    )
  }
}
