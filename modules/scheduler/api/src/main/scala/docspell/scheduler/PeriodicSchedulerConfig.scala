/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import docspell.common._

case class PeriodicSchedulerConfig(
    name: Ident,
    wakeupPeriod: Duration
)

object PeriodicSchedulerConfig {
  def default(id: Ident): PeriodicSchedulerConfig =
    PeriodicSchedulerConfig(id, Duration.minutes(10))
}
