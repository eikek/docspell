/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons.runner

import fs2.io.file.Path

import docspell.common.Duration
import docspell.common.exec.{Args, Env, SysCmd}

/** Builder for a docker system command. */
case class DockerBuilder(
    dockerBinary: String,
    subCmd: String,
    timeout: Duration,
    containerName: Option[String] = None,
    env: Env = Env.empty,
    mounts: Args = Args.empty,
    network: Option[String] = Some("host"),
    workingDir: Option[String] = None,
    imageName: Option[String] = None,
    cntCmd: Args = Args.empty
) {
  def containerCmd(args: Args): DockerBuilder =
    copy(cntCmd = args)
  def containerCmd(args: Seq[String]): DockerBuilder =
    copy(cntCmd = Args(args))

  def imageName(name: String): DockerBuilder =
    copy(imageName = Some(name))

  def workDirectory(dir: String): DockerBuilder =
    copy(workingDir = Some(dir))

  def withDockerBinary(bin: String): DockerBuilder =
    copy(dockerBinary = bin)

  def withSubCmd(cmd: String): DockerBuilder =
    copy(subCmd = cmd)

  def withEnv(key: String, value: String): DockerBuilder =
    copy(env = env.add(key, value))

  def withEnv(moreEnv: Env): DockerBuilder =
    copy(env = env ++ moreEnv)

  def privateNetwork(flag: Boolean): DockerBuilder =
    if (flag) copy(network = Some("none"))
    else copy(network = Some("host"))

  def mount(
      hostDir: Path,
      cntDir: Option[String] = None,
      readOnly: Boolean = true
  ): DockerBuilder = {
    val target = cntDir.getOrElse(hostDir.toString)
    val ro = Option.when(readOnly)(",readonly").getOrElse("")
    val opt = s"type=bind,source=$hostDir,target=$target${ro}"
    copy(mounts = mounts.append("--mount", opt))
  }

  def withName(containerName: String): DockerBuilder =
    copy(containerName = Some(containerName))

  def build: SysCmd =
    SysCmd(dockerBinary, buildArgs).withTimeout(timeout)

  private def buildArgs: Args =
    Args
      .of(subCmd)
      .append("--rm")
      .option("--name", containerName)
      .append(mounts)
      .option("--network", network)
      .append(env.mapConcat((k, v) => List("--env", s"${k}=${v}")))
      .option("-w", workingDir)
      .appendOpt(imageName)
      .append(cntCmd)
}
