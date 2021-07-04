/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

import scala.concurrent.ExecutionContext

/** Captures thread pools to use in an application.
  */
case class Pools(
    connectEC: ExecutionContext,
    httpClientEC: ExecutionContext,
    restEC: ExecutionContext
)
