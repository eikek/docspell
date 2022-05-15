/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.joex

import docspell.backend.joex.AddonOps.AddonRunConfigRef
import docspell.logging.Logger

trait LoggerExtension {

  implicit final class LoggerDataOps[F[_]](self: Logger[F]) {
    def withRunConfig(t: AddonRunConfigRef): Logger[F] =
      self.capture("addon-task-id", t.id)
  }
}
