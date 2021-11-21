/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import cats.data.Kleisli

import docspell.notification.api.{Event, EventContext}
import docspell.notification.impl.context._

import doobie._

object DbEventContext {

  type Factory = EventContext.Factory[ConnectionIO, Event]

  def apply: Factory =
    Kleisli {
      case ev: Event.TagsChanged =>
        TagsChangedCtx.apply.run(ev)

      case ev: Event.SetFieldValue =>
        SetFieldValueCtx.apply.run(ev)

      case ev: Event.DeleteFieldValue =>
        DeleteFieldValueCtx.apply.run(ev)

      case ev: Event.ItemSelection =>
        ItemSelectionCtx.apply.run(ev)

      case ev: Event.JobSubmitted =>
        JobSubmittedCtx.apply.run(ev)

      case ev: Event.JobDone =>
        JobDoneCtx.apply.run(ev)
    }

}
