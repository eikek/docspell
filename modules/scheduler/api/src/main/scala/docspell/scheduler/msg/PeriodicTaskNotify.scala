package docspell.scheduler.msg

import docspell.pubsub.api.{Topic, TypedTopic}

/** A generic notification to the periodic task scheduler to look for new work. */
object PeriodicTaskNotify {
  def apply(): TypedTopic[Unit] =
    TypedTopic[Unit](Topic("periodic-task-notify"))
}
