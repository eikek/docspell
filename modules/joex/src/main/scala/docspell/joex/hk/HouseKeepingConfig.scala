/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
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
    cleanupDownloads: CleanupDownloads,
    checkNodes: CheckNodes,
    integrityCheck: IntegrityCheck
)

object HouseKeepingConfig {

  case class CleanupInvites(enabled: Boolean, olderThan: Duration)

  case class CleanupJobs(enabled: Boolean, olderThan: Duration, deleteBatch: Int)

  case class CleanupDownloads(enabled: Boolean, olderThan: Duration)

  case class CleanupRememberMe(enabled: Boolean, olderThan: Duration)

  case class CheckNodes(enabled: Boolean, minNotFound: Int)

  case class IntegrityCheck(enabled: Boolean)
}
