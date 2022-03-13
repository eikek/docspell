/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import docspell.common._

case class SchedulerConfig(
    name: Ident,
    poolSize: Int,
    countingScheme: CountingScheme,
    retries: Int,
    retryDelay: Duration,
    logBufferSize: Int,
    wakeupPeriod: Duration
)

object SchedulerConfig {

  def default(id: Ident) = SchedulerConfig(
    name = id,
    poolSize = 1,
    countingScheme = CountingScheme(3, 1),
    retries = 5,
    retryDelay = Duration.seconds(30),
    logBufferSize = 500,
    wakeupPeriod = Duration.minutes(10)
  )
}
