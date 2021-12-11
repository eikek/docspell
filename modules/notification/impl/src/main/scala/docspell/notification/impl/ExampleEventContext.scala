/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import cats.data.Kleisli
import cats.effect.kernel.Sync

import docspell.notification.api.{Event, EventContext}
import docspell.notification.impl.context._

object ExampleEventContext {

  type Factory[F[_]] = EventContext.Example[F, Event]

  def apply[F[_]: Sync]: Factory[F] =
    Kleisli {
      case ev: Event.TagsChanged =>
        TagsChangedCtx.sample.run(ev)

      case ev: Event.SetFieldValue =>
        SetFieldValueCtx.sample.run(ev)

      case ev: Event.DeleteFieldValue =>
        DeleteFieldValueCtx.sample.run(ev)

      case ev: Event.ItemSelection =>
        ItemSelectionCtx.sample.run(ev)

      case ev: Event.JobSubmitted =>
        JobSubmittedCtx.sample.run(ev)

      case ev: Event.JobDone =>
        JobDoneCtx.sample.run(ev)
    }
}
