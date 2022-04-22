/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.exec

import fs2.io.file.Path

case class Args(values: Seq[String]) {

  def option(key: String, value: String): Args =
    Args(values ++ Seq(key, value))

  def option(key: String, value: Option[String]): Args =
    value.map(v => option(key, v)).getOrElse(this)

  def appendOpt(v: Option[String]): Args =
    v.map(e => Args(values :+ e)).getOrElse(this)

  def append(v: String, vs: String*): Args =
    Args(values ++ (v +: vs))

  def append(path: Path): Args =
    append(path.toString)

  def append(args: Args): Args =
    Args(values ++ args.values)

  def append(args: Seq[String]): Args =
    Args(values ++ args)

  def prepend(v: String): Args =
    Args(v +: values)

  def prependWhen(flag: Boolean)(v: String) =
    if (flag) prepend(v) else this

  def cmdString: String =
    values.mkString(" ")
}

object Args {
  val empty: Args = Args(Seq.empty)

  def of(v: String*): Args =
    Args(v)
}
