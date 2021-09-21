/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.updatecheck

import docspell.joex.BuildInfo

trait ThisVersion {
  def get: String
}

object ThisVersion {
  def default: ThisVersion =
    constant(BuildInfo.version)

  def constant(value: String): ThisVersion = new ThisVersion {
    override def get: String = value
  }
}
