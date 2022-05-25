/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.addon

import cats.data.OptionT
import cats.effect._
import cats.syntax.all._

import docspell.addons.AddonTriggerType
import docspell.backend.joex.AddonOps
import docspell.common.{ItemAddonTaskArgs, MetaProposalList}
import docspell.joex.process.ItemData
import docspell.scheduler.{PermanentError, Task}
import docspell.store.Store
import docspell.store.queries.QAttachment
import docspell.store.records._

object ItemAddonTask extends AddonTaskExtension {
  type Args = ItemAddonTaskArgs
  val name = ItemAddonTaskArgs.taskName

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn(s"Cancelling ${name.id} task"))

  def apply[F[_]: Async](ops: AddonOps[F], store: Store[F]): Task[F, Args, Result] =
    Task { ctx =>
      (for {
        item <- OptionT(
          store.transact(
            RItem.findByIdAndCollective(ctx.args.itemId, ctx.args.collective)
          )
        )
        data <- OptionT.liftF(makeItemData(store, item))
        inner = GenericItemAddonTask.addonResult(
          ops,
          store,
          AddonTriggerType.ExistingItem,
          ctx.args.addonRunConfigs
        )(ctx.args.collective, data, None)
        execResult <- OptionT.liftF(inner.run(ctx.unit))
        _ <- OptionT.liftF(execResult.combined.raiseErrorIfNeeded[F])
      } yield Result(
        execResult.combined.addonResult,
        execResult.runConfigs.flatMap(_.refs).map(_.archive.nameAndVersion).distinct
      )).getOrElseF(
        Async[F].raiseError(
          PermanentError(
            new NoSuchElementException(s"Item not found for id: ${ctx.args.itemId.id}!")
          )
        )
      )
    }

  def makeItemData[F[_]: Async](store: Store[F], item: RItem): F[ItemData] =
    for {
      attachs <- store.transact(RAttachment.findByItem(item.id))
      rmeta <- store.transact(QAttachment.getAttachmentMetaOfItem(item.id))
      rsource <- store.transact(RAttachmentSource.findByItem(item.id))
      proposals <- store.transact(QAttachment.getMetaProposals(item.id, item.cid))
      tags <- store.transact(RTag.findByItem(item.id))
    } yield ItemData(
      item = item,
      attachments = attachs,
      metas = rmeta,
      dateLabels = Vector.empty,
      originFile = rsource.map(r => (r.id, r.fileId)).toMap,
      givenMeta = proposals,
      tags = tags.map(_.name).toList,
      classifyProposals = MetaProposalList.empty,
      classifyTags = Nil
    )
}
