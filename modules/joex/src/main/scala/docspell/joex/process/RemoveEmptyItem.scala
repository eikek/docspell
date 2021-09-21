/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.effect._
import cats.implicits._

import docspell.backend.ops.OItem
import docspell.common._
import docspell.joex.scheduler.Task

object RemoveEmptyItem {

  def apply[F[_]: Sync](
      ops: OItem[F]
  )(data: ItemData): Task[F, ProcessItemArgs, ItemData] =
    if (data.item.state.isInvalid && data.attachments.isEmpty)
      Task { ctx =>
        for {
          _ <- ctx.logger.warn(s"Removing item as it doesn't have any attachments!")
          n <- ops.deleteItem(data.item.id, data.item.cid)
          _ <- ctx.logger.warn(s"Removed item ($n). No item has been created!")
        } yield data
      }
    else
      Task.pure(data)

}
