/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.bc

import docspell.common.CollectiveId

trait BackendCommandRunner[F[_], A] {

  def run(collective: CollectiveId, cmd: BackendCommand): F[A]

  def runAll(collective: CollectiveId, cmds: List[BackendCommand]): F[A]

}
