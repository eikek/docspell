/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.bc

import docspell.common.Ident

trait BackendCommandRunner[F[_], A] {

  def run(collective: Ident, cmd: BackendCommand): F[A]

  def runAll(collective: Ident, cmds: List[BackendCommand]): F[A]

}
