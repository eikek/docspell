package docspell.joex.hk

import com.github.eikek.calev.CalEvent
import docspell.common._

import HouseKeepingConfig._

case class HouseKeepingConfig(
  schedule: CalEvent,
  cleanupInvites: CleanupInvites
)

object HouseKeepingConfig {

  case class CleanupInvites(olderThan: Duration)

}
