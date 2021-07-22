/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.restserver

import docspell.backend.BackendApp

trait RestApp[F[_]] {

  def init: F[Unit]

  def config: Config

  def backend: BackendApp[F]
}
