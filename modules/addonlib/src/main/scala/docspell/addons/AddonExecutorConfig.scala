/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import docspell.addons.AddonExecutorConfig._
import docspell.common.Duration
import docspell.common.exec.{Args, SysCmd}

case class AddonExecutorConfig(
    runner: List[RunnerType],
    runTimeout: Duration,
    nspawn: NSpawn,
    nixRunner: NixConfig,
    dockerRunner: DockerConfig,
    failFast: Boolean
)

object AddonExecutorConfig {

  case class NSpawn(
      enabled: Boolean,
      sudoBinary: String,
      nspawnBinary: String,
      containerWait: Duration
  ) {
    val nspawnVersion =
      SysCmd(nspawnBinary, Args.of("--version")).withTimeout(Duration.seconds(2))
  }

  case class NixConfig(
      nixBinary: String,
      buildTimeout: Duration
  )

  case class DockerConfig(
      dockerBinary: String,
      buildTimeout: Duration
  ) {
    def dockerBuild(imageName: String): SysCmd =
      SysCmd(dockerBinary, "build", "-t", imageName, ".").withTimeout(buildTimeout)
  }
}
