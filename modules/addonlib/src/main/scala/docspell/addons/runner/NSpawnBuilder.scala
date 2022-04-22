/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons.runner

import fs2.io.file.Path

import docspell.common.exec.{Args, Env, SysCmd}

case class NSpawnBuilder(
    child: SysCmd,
    chroot: Path,
    spawnBinary: String = "systemd-nspawn",
    sudoBinary: String = "sudo",
    args: Args = Args.empty,
    env: Env = Env.empty
) {

  def withNSpawnBinary(bin: String): NSpawnBuilder =
    copy(spawnBinary = bin)

  def withSudoBinary(bin: String): NSpawnBuilder =
    copy(sudoBinary = bin)

  def withEnv(key: String, value: String): NSpawnBuilder =
    copy(args = args.append(s"--setenv=$key=$value"))

  def withEnvOpt(key: String, value: Option[String]): NSpawnBuilder =
    value.map(v => withEnv(key, v)).getOrElse(this)

  def withName(containerName: String): NSpawnBuilder =
    copy(args = args.append(s"--machine=$containerName"))

  def mount(
      hostDir: Path,
      cntDir: Option[String] = None,
      readOnly: Boolean = true
  ): NSpawnBuilder = {
    val bind = if (readOnly) "--bind-ro" else "--bind"
    val target = cntDir.map(dir => s":$dir").getOrElse("")
    copy(args = args.append(s"${bind}=${hostDir}${target}"))
  }

  def workDirectory(dir: String): NSpawnBuilder =
    copy(args = args.append(s"--chdir=$dir"))

  def portMap(port: Int): NSpawnBuilder =
    copy(args = args.append("-p", port.toString))

  def privateNetwork(flag: Boolean): NSpawnBuilder =
    if (flag) copy(args = args.append("--private-network"))
    else this

  def build: SysCmd =
    SysCmd(
      program = if (sudoBinary.nonEmpty) sudoBinary else spawnBinary,
      args = buildArgs,
      timeout = child.timeout,
      env = env
    )

  private def buildArgs: Args =
    Args
      .of("--private-users=identity") // can't use -U because need writeable bind mounts
      .append("--notify-ready=yes")
      .append("--ephemeral")
      .append("--as-pid2")
      .append("--console=pipe")
      .append("--no-pager")
      .append("--bind-ro=/bin")
      .append("--bind-ro=/usr/bin")
      .append("--bind-ro=/nix/store")
      .append(s"--directory=$chroot")
      .append(args)
      .append(child.env.map((n, v) => s"--setenv=$n=$v"))
      .prependWhen(sudoBinary.nonEmpty)(spawnBinary)
      .append("--")
      .append(child.program)
      .append(child.args)
}
