package docspell.joex.hk

import docspell.common._
import docspell.joex.hk.HouseKeepingConfig._

import com.github.eikek.calev.CalEvent

case class HouseKeepingConfig(
    schedule: CalEvent,
    cleanupInvites: CleanupInvites,
    cleanupJobs: CleanupJobs
)

object HouseKeepingConfig {

  case class CleanupInvites(enabled: Boolean, olderThan: Duration)

  case class CleanupJobs(enabled: Boolean, olderThan: Duration, deleteBatch: Int)

}
