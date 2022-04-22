/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell

import cats.data.Kleisli

package object addons {

  type AddonExec[F[_]] = Kleisli[F, InputEnv, AddonExecutionResult]

}
