/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import scala.concurrent.ExecutionContext

/** Captures thread pools to use in an application. */
case class Pools(
    connectEC: ExecutionContext,
    httpClientEC: ExecutionContext,
    restEC: ExecutionContext
)
