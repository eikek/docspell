/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.effect.Resource
import fs2.io.file.{Files, Path}

import docspell.common.exec.Env

case class InputEnv(
    addons: List[AddonRef],
    baseDir: Path,
    outputDir: Path,
    cacheDir: Path,
    env: Env
) {
  def addEnv(key: String, value: String): InputEnv =
    copy(env = env.add(key, value))

  def addEnv(vp: (String, String)*): InputEnv =
    copy(env = env.addAll(vp.toMap))

  def addEnv(vm: Map[String, String]): InputEnv =
    copy(env = env ++ Env(vm))

  def withTempBase[F[_]: Files]: Resource[F, InputEnv] =
    Directory.temp(baseDir, "addon-").map(path => copy(baseDir = path))
}
