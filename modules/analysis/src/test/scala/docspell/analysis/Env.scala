/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.analysis

object Env {

  def isCI = bool("CI")

  def bool(key: String): Boolean =
    string(key).contains("true")

  def string(key: String): Option[String] =
    Option(System.getenv(key)).filter(_.nonEmpty)
}
