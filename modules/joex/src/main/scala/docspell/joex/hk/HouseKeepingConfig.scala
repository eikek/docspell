/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.hk

import docspell.common._
import docspell.joex.hk.HouseKeepingConfig._

import com.github.eikek.calev.CalEvent

case class HouseKeepingConfig(
    schedule: CalEvent,
    cleanupInvites: CleanupInvites,
    cleanupJobs: CleanupJobs,
    cleanupRememberMe: CleanupRememberMe,
    checkNodes: CheckNodes
)

object HouseKeepingConfig {

  case class CleanupInvites(enabled: Boolean, olderThan: Duration)

  case class CleanupJobs(enabled: Boolean, olderThan: Duration, deleteBatch: Int)

  case class CleanupRememberMe(enabled: Boolean, olderThan: Duration)

  case class CheckNodes(enabled: Boolean, minNotFound: Int)

}
