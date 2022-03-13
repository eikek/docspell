/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.msg

import docspell.pubsub.api.{Topic, TypedTopic}

/** A generic notification to the job executors to look for new work. */
object JobsNotify {
  def apply(): TypedTopic[Unit] =
    TypedTopic[Unit](Topic("jobs-notify"))
}
