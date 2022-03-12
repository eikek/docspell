package docspell.scheduler.msg

import docspell.pubsub.api.{Topic, TypedTopic}

/** A generic notification to the job executors to look for new work. */
object JobsNotify {
  def apply(): TypedTopic[Unit] =
    TypedTopic[Unit](Topic("jobs-notify"))
}
