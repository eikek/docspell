/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import docspell.backend.BackendApp

trait RestApp[F[_]] {

  def init: F[Unit]

  def config: Config

  def backend: BackendApp[F]
}
