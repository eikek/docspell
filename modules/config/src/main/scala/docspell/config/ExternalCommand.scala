/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.config

import docspell.common.Duration
import docspell.common.Ident
import docspell.common.exec.Env
import docspell.common.exec.SysCmd
import docspell.config.ExternalCommand.ArgMapping

final case class ExternalCommand(
    program: String,
    args: List[String],
    env: Map[String, String],
    timeout: Duration,
    argMappings: Map[Ident, ArgMapping]
) {
  def resolve(vars: Map[String, String]): SysCmd = {
    val replace = ExternalCommand.replaceString(vars) _
    val resolvedArgMappings =
      argMappings.view.mapValues(_.resolve(replace).firstMatch).toMap
    val resolvedArgs = args.map(replace).flatMap { arg =>
      resolvedArgMappings
        .find(e => s"{{${e._1.id}}}" == arg)
        .map(_._2)
        .getOrElse(List(arg))
    }

    SysCmd(replace(program), resolvedArgs: _*)
      .withTimeout(timeout)
      .withEnv(_ => Env(env).modifyValue(replace))
  }
}

object ExternalCommand {
  final case class ArgMapping(
      value: String,
      mappings: List[ArgMatch]
  ) {
    private[config] def resolve(replace: String => String): ArgMapping =
      ArgMapping(replace(value), mappings.map(_.resolve(replace)))

    def firstMatch: List[String] =
      mappings.find(am => value.matches(am.matches)).map(_.args).getOrElse(Nil)
  }

  final case class ArgMatch(
      matches: String,
      args: List[String]
  ) {
    private[config] def resolve(replace: String => String): ArgMatch =
      ArgMatch(replace(matches), args.map(replace))
  }

  private def replaceString(vars: Map[String, String])(in: String): String =
    vars.foldLeft(in) { case (result, (name, value)) =>
      val key = s"{{$name}}"
      result.replace(key, value)
    }
}
