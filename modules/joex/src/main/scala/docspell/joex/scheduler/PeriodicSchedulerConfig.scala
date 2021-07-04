/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.scheduler

import docspell.common._

case class PeriodicSchedulerConfig(
    name: Ident,
    wakeupPeriod: Duration
)
