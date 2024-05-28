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
import docspell.common.exec.Env
import docspell.common.{Duration, Ident, LenientUri}
import docspell.logging.TestLoggingConfig

import munit.CatsEffectSuite

trait Fixtures extends TestLoggingConfig { self: CatsEffectSuite =>

  val files: Files[IO] = Files[IO]

  def id(str: String): Ident = Ident.unsafe(str)

  val dummyAddonUrl =
    LenientUri.fromJava(getClass.getResource("/docspell-dummy-addon-master.zip"))

  val miniAddonUrl =
    LenientUri.fromJava(getClass.getResource("/minimal-addon.zip"))

  val singleFileAddonUrl =
    LenientUri.fromJava(getClass.getResource("/docspell-addon-single-file.zip"))

  val dummyAddonMeta =
    AddonMeta(
      meta =
        AddonMeta.Meta("dummy-addon", "2.9", "Some dummy addon only for testing.\n".some),
      triggers = Some(
        Set(Scheduled, FinalProcessItem, FinalReprocessItem)
      ),
      None,
      runner = Runner(
        nix = NixRunner(enable = true).some,
        docker = DockerRunner(
          enable = true,
          image = None,
          build = "Dockerfile".some
        ).some,
        trivial = TrivialRunner(enable = true, "src/addon.sh").some
      ).some,
      options = Options(networking = true, collectOutput = true).some
    )

  def baseTempDir: Path =
    Path(s"/tmp/target/test-temp")

  val tempDir =
    ResourceFunFixture[Path](
      Resource.eval(Files[IO].createDirectories(baseTempDir)) *>
        Files[IO]
          .tempDirectory(baseTempDir.some, "run-", PosixPermissions.fromOctal("777"))
    )

  def testExecutorConfig(
      runner: RunnerType,
      runners: RunnerType*
  ): AddonExecutorConfig = {
    val nspawn = NSpawn(enabled = false, "sudo", "systemd-nspawn", Duration.millis(100))
    AddonExecutorConfig(
      runner = runner :: runners.toList,
      runTimeout = Duration.minutes(2),
      nspawn = nspawn,
      nixRunner = NixConfig("nix", Duration.minutes(2)),
      dockerRunner = DockerConfig("docker", Duration.minutes(2)),
      failFast = true
    )
  }

  def createInputEnv(
      dir: Path,
      addon: Resource[IO, AddonArchive],
      more: Resource[IO, AddonArchive]*
  ): Resource[IO, InputEnv] =
    (addon :: more.toList)
      .traverse(_.map(a => AddonRef(a, "")))
      .map(addons => InputEnv(addons, dir, dir, dir, Env.empty))

}
