/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.exec

import docspell.common._

final case class SysCmd(
    program: String,
    args: Args,
    env: Env,
    timeout: Duration
) {

  def withArgs(f: Args => Args): SysCmd =
    copy(args = f(args))

  def withTimeout(to: Duration): SysCmd =
    copy(timeout = to)

  def withEnv(f: Env => Env): SysCmd =
    copy(env = f(env))

  def addEnv(env: Env): SysCmd =
    withEnv(_.addAll(env))

  def cmdString: String =
    s"$program ${args.cmdString}"

  private[exec] def toCmd: Seq[String] =
    program +: args.values
}

object SysCmd {
  def apply(prg: String, args: String*): SysCmd =
    apply(prg, Args(args))

  def apply(prg: String, args: Args): SysCmd =
    SysCmd(prg, args, Env.empty, Duration.minutes(2))
}
