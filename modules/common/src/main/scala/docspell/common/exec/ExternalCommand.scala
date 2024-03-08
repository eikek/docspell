/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.exec

import docspell.common.Duration
import docspell.common.Ident
import docspell.common.exec.Env
import docspell.common.exec.ExternalCommand.ArgMapping
import docspell.common.exec.SysCmd

final case class ExternalCommand(
    program: String,
    args: Seq[String],
    timeout: Duration,
    env: Map[String, String] = Map.empty,
    argMappings: Map[Ident, ArgMapping] = Map.empty
) {
  def withVars(vars: Map[String, String]): ExternalCommand.WithVars =
    ExternalCommand.WithVars(this, vars)

  import ExternalCommand.pattern

  def resolve(vars: Map[String, String]): SysCmd = {
    val replace = ExternalCommand.replaceString(vars) _
    val resolvedArgMappings =
      argMappings.view.mapValues(_.resolve(replace).firstMatch).toMap
    val resolvedArgs = args.map(replace).flatMap { arg =>
      resolvedArgMappings
        .find(e => pattern(e._1.id) == arg)
        .map(_._2)
        .getOrElse(List(arg))
    }

    SysCmd(replace(program), resolvedArgs: _*)
      .withTimeout(timeout)
      .withEnv(_ => Env(env).modifyValue(replace))
  }
}

object ExternalCommand {
  private val openPattern = "{{"
  private val closePattern = "}}"

  private def pattern(s: String): String = s"${openPattern}${s}${closePattern}"

  def apply(program: String, args: Seq[String], timeout: Duration): ExternalCommand =
    ExternalCommand(program, args, timeout, Map.empty, Map.empty)

  final case class ArgMapping(
      value: String,
      mappings: List[ArgMatch]
  ) {
    private[exec] def resolve(replace: String => String): ArgMapping =
      ArgMapping(replace(value), mappings.map(_.resolve(replace)))

    def firstMatch: List[String] =
      mappings.find(am => value.matches(am.matches)).map(_.args).getOrElse(Nil)
  }

  final case class ArgMatch(
      matches: String,
      args: List[String]
  ) {
    private[exec] def resolve(replace: String => String): ArgMatch =
      ArgMatch(replace(matches), args.map(replace))
  }

  private def replaceString(vars: Map[String, String])(in: String): String =
    vars.foldLeft(in) { case (result, (name, value)) =>
      val key = s"{{$name}}"
      result.replace(key, value)
    }

  final case class WithVars(cmd: ExternalCommand, vars: Map[String, String]) {
    def resolved: SysCmd = cmd.resolve(vars)
    def append(more: (String, String)*): WithVars =
      WithVars(cmd, vars ++ more.toMap)

    def withVar(key: String, value: String): WithVars =
      WithVars(cmd, vars.updated(key, value))

    def withVarOption(key: String, value: Option[String]): WithVars =
      value.map(withVar(key, _)).getOrElse(this)
  }
}
