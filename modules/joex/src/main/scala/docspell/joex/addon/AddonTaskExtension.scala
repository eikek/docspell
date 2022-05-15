/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.addon

import cats.MonadError

import docspell.addons.AddonExecutionResult
import docspell.scheduler.PermanentError

trait AddonTaskExtension {
  implicit final class AddonExecutionResultOps(self: AddonExecutionResult) {
    def raiseErrorIfNeeded[F[_]](implicit m: MonadError[F, Throwable]): F[Unit] =
      if (self.isFailure && self.pure) {
        m.raiseError(new Exception(s"Addon execution failed: $self"))
      } else if (self.isFailure) {
        m.raiseError(
          PermanentError(
            new Exception(
              "Addon execution failed. Do not retry, because some addons were impure."
            )
          )
        )
      } else m.pure(())

  }
}
