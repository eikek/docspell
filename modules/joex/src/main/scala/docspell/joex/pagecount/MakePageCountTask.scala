/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.pagecount

import cats.effect._
import cats.implicits._
import docspell.common._
import docspell.joex.process.AttachmentPageCount
import docspell.scheduler.Context
import docspell.scheduler.Task
import docspell.store.Store
import docspell.store.records.RAttachment
import docspell.store.records.RAttachmentMeta

object MakePageCountTask {

  type Args = MakePageCountArgs

  def apply[F[_]: Sync](store: Store[F]): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        exists <- pageCountExists(ctx, store)
        _ <-
          if (exists)
            ctx.logger.info(
              s"PageCount already exists for attachment ${ctx.args.attachment}. Skipping."
            )
          else
            ctx.logger.info(
              s"Reading page-count for attachment ${ctx.args.attachment}"
            ) *> generatePageCount(ctx, store)
      } yield ()
    }

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn("Cancelling make-page-count task"))

  private def generatePageCount[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F]
  ): F[Unit] =
    for {
      ra <- store.transact(RAttachment.findById(ctx.args.attachment))
      _ <- ra
        .map(AttachmentPageCount.createPageCount(ctx, store))
        .getOrElse(
          ctx.logger.warn(s"No attachment found with id: ${ctx.args.attachment}")
        )
    } yield ()

  private def pageCountExists[F[_]](ctx: Context[F, Args], store: Store[F]): F[Boolean] =
    store.transact(
      RAttachmentMeta
        .findPageCountById(ctx.args.attachment)
        .map(_.exists(_ > 0))
    )

}
