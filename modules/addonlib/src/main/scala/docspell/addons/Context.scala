/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import fs2.io.file.Path

import docspell.common._
import docspell.common.exec.{Args, Env, SysCmd}

/** Context a list of addons is executed in.
  *
  * Each addon has its own `addonDir`, but all share the same `baseDir` in one run.
  */
case class Context(
    addon: AddonRef,
    meta: AddonMeta,
    baseDir: Path,
    addonDir: Path,
    outputDir: Path,
    cacheDir: Path
) {
  def userInputFile = Context.userInputFile(baseDir)
  def tempDir = Context.tempDir(baseDir)

  private[addons] def addonCommand(
      binary: String,
      timeout: Duration,
      relativeToBase: Boolean,
      outputDir: Option[String],
      cacheDir: Option[String]
  ): SysCmd = {
    val execBin = Option
      .when(relativeToBase)(binary)
      .getOrElse((baseDir / binary).toString)

    val input = Option
      .when(relativeToBase)(baseDir.relativize(userInputFile))
      .getOrElse(userInputFile)

    val allArgs =
      Args(meta.args.getOrElse(Nil)).append(input)
    val envAddonDir = Option
      .when(relativeToBase)(baseDir.relativize(addonDir))
      .getOrElse(addonDir)
    val envTmpDir = Option
      .when(relativeToBase)(baseDir.relativize(tempDir))
      .getOrElse(tempDir)
    val outDir = outputDir.getOrElse(this.outputDir.toString)
    val cache = cacheDir.getOrElse(this.cacheDir.toString)
    val moreEnv =
      Env.of(
        "ADDON_DIR" -> envAddonDir.toString,
        "TMPDIR" -> envTmpDir.toString,
        "TMP_DIR" -> envTmpDir.toString,
        "OUTPUT_DIR" -> outDir,
        "CACHE_DIR" -> cache
      )

    SysCmd(execBin, allArgs).withTimeout(timeout).addEnv(moreEnv)
  }
}

object Context {
  def userInputFile(base: Path): Path =
    base / "arguments" / "user-input"
  def tempDir(base: Path): Path =
    base / "temp"
}
