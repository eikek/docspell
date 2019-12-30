package docspell.joex.scheduler

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

  val default = SchedulerConfig(
    name = Ident.unsafe("default-scheduler"),
    poolSize = 2 // math.max(2, Runtime.getRuntime.availableProcessors / 2)
    ,
    countingScheme = CountingScheme(2, 1),
    retries = 5,
    retryDelay = Duration.seconds(30),
    logBufferSize = 500,
    wakeupPeriod = Duration.minutes(10)
  )
}
