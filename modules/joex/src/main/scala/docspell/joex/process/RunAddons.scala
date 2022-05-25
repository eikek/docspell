/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.effect._
import cats.syntax.all._

import docspell.addons.AddonTriggerType
import docspell.backend.joex.AddonOps
import docspell.common.ProcessItemArgs
import docspell.joex.addon.GenericItemAddonTask
import docspell.scheduler.Task
import docspell.store.Store

/** Run registered addons in the context of item processing. The addon has access to the
  * current item data and can apply custom processing logic.
  */
object RunAddons {
  type Args = ProcessItemArgs

  def apply[F[_]: Async](
      ops: AddonOps[F],
      store: Store[F],
      trigger: AddonTriggerType
  )(
      data: ItemData
  ): Task[F, Args, ItemData] =
    if (data.item.state.isInvalid && data.attachments.isEmpty) {
      Task.pure(data)
    } else
      Task { ctx =>
        val inner = GenericItemAddonTask(ops, store, trigger, Set.empty)(
          ctx.args.meta.collective,
          data,
          ctx.args.meta.some
        )
        inner.run(ctx.unit)
      }
}
