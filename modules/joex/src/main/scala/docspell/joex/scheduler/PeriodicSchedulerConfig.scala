package docspell.joex.scheduler

import docspell.common._

case class PeriodicSchedulerConfig(
    name: Ident,
    wakeupPeriod: Duration
)
