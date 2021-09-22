/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.joex.scheduler.{Context, Task}
import docspell.store.AddResult
import docspell.store.records._

/** Saves the proposals in the database */
object SaveProposals {
  type Args = ProcessItemArgs

  def apply[F[_]: Sync](data: ItemData): Task[F, Args, ItemData] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info("Storing proposals")
        _ <- data.metas
          .traverse(rm =>
            ctx.logger.debug(
              s"Storing attachment proposals: ${rm.proposals}"
            ) *> ctx.store.transact(RAttachmentMeta.updateProposals(rm.id, rm.proposals))
          )
        _ <-
          if (data.classifyProposals.isEmpty && data.classifyTags.isEmpty) 0.pure[F]
          else saveItemProposal(ctx, data)
      } yield data
    }

  def saveItemProposal[F[_]: Sync](ctx: Context[F, Args], data: ItemData): F[Unit] = {
    def upsert(v: RItemProposal): F[Int] =
      ctx.store.add(RItemProposal.insert(v), RItemProposal.exists(v.itemId)).flatMap {
        case AddResult.Success => 1.pure[F]
        case AddResult.EntityExists(_) =>
          ctx.store.transact(RItemProposal.update(v))
        case AddResult.Failure(ex) =>
          ctx.logger.warn(s"Could not store item proposals: ${ex.getMessage}") *> 0
            .pure[F]
      }

    for {
      _ <- ctx.logger.debug(s"Storing classifier proposals: ${data.classifyProposals}")
      tags <- ctx.store.transact(
        RTag.findAllByNameOrId(data.classifyTags, ctx.args.meta.collective)
      )
      tagRefs = tags.map(t => IdRef(t.tagId, t.name))
      now <- Timestamp.current[F]
      value = RItemProposal(data.item.id, data.classifyProposals, tagRefs.toList, now)
      _ <- upsert(value)
    } yield ()
  }
}
