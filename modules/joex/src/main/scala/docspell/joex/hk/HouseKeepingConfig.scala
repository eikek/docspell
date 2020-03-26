package docspell.joex.hk

import com.github.eikek.calev.CalEvent
import docspell.common._

import HouseKeepingConfig._

case class HouseKeepingConfig(
    schedule: CalEvent,
    cleanupInvites: CleanupInvites,
    cleanupJobs: CleanupJobs
)

object HouseKeepingConfig {

  case class CleanupInvites(enabled: Boolean, olderThan: Duration)

  case class CleanupJobs(enabled: Boolean, olderThan: Duration, deleteBatch: Int)

}
