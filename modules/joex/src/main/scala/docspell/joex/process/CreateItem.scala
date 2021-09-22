/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.data.NonEmptyList
import cats.data.OptionT
import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.joex.scheduler.{Context, Task}
import docspell.store.queries.QItem
import docspell.store.records._

/** Task that creates the item. */
object CreateItem {

  def apply[F[_]: Sync]: Task[F, ProcessItemArgs, ItemData] =
    findExisting[F].flatMap {
      case Some(ri) => Task.pure(ri)
      case None     => createNew[F]
    }

  def createNew[F[_]: Sync]: Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      def isValidFile(fm: RFileMeta) =
        ctx.args.meta.validFileTypes.isEmpty ||
          ctx.args.meta.validFileTypes.toSet
            .contains(fm.mimetype)

      def fileMetas(itemId: Ident, now: Timestamp) =
        Stream
          .eval(ctx.store.transact(RAttachment.nextPosition(itemId)))
          .flatMap { offset =>
            Stream
              .emits(ctx.args.files)
              .evalMap(f =>
                ctx.store.fileStore.findMeta(f.fileMetaId).value.map(fm => (f, fm))
              )
              .collect { case (f, Some(fm)) if isValidFile(fm) => f }
              .zipWithIndex
              .evalMap { case (f, index) =>
                Ident
                  .randomId[F]
                  .map(id =>
                    RAttachment(
                      id,
                      itemId,
                      f.fileMetaId,
                      index.toInt + offset,
                      now,
                      f.name
                    )
                  )
              }
          }
          .compile
          .toVector

      val loadItemOrInsertNew =
        ctx.args.meta.itemId match {
          case Some(id) =>
            (for {
              _ <- OptionT.liftF(
                ctx.logger.info(
                  s"Loading item with id ${id.id} to ammend"
                )
              )
              item <- OptionT(
                ctx.store
                  .transact(RItem.findByIdAndCollective(id, ctx.args.meta.collective))
              )
            } yield (1, item))
              .getOrElseF(Sync[F].raiseError(new Exception(s"Item not found.")))
          case None =>
            for {
              _ <- ctx.logger.info(
                s"Creating new item with ${ctx.args.files.size} attachment(s)"
              )
              item <- RItem.newItem[F](
                ctx.args.meta.collective,
                ctx.args.makeSubject,
                ctx.args.meta.sourceAbbrev,
                ctx.args.meta.direction.getOrElse(Direction.Incoming),
                ItemState.Premature
              )
              n <- ctx.store.transact(RItem.insert(item))
            } yield (n, item)
        }

      for {
        time <- Duration.stopTime[F]
        it <- loadItemOrInsertNew
        _ <- if (it._1 != 1) storeItemError[F](ctx) else ().pure[F]
        now <- Timestamp.current[F]
        fm <- fileMetas(it._2.id, now)
        k <- fm.traverse(insertAttachment(ctx))
        _ <- logDifferences(ctx, fm, k.sum)
        dur <- time
        _ <- ctx.logger.info(s"Creating item finished in ${dur.formatExact}")
      } yield ItemData(
        it._2,
        fm,
        Vector.empty,
        Vector.empty,
        fm.map(a => a.id -> a.fileId).toMap,
        MetaProposalList.empty,
        Nil,
        MetaProposalList.empty,
        Nil
      )
    }

  def insertAttachment[F[_]](ctx: Context[F, _])(ra: RAttachment): F[Int] = {
    val rs = RAttachmentSource.of(ra)
    ctx.store.transact(for {
      n <- RAttachment.insert(ra)
      _ <- RAttachmentSource.insert(rs)
    } yield n)
  }

  private def findExisting[F[_]: Sync]: Task[F, ProcessItemArgs, Option[ItemData]] =
    Task { ctx =>
      val states = ItemState.invalidStates
      val fileMetaIds = ctx.args.files.map(_.fileMetaId).toSet
      for {
        cand <- ctx.store.transact(QItem.findByFileIds(fileMetaIds.toSeq, states))
        _ <-
          if (cand.nonEmpty)
            ctx.logger.warn(s"Found ${cand.size} existing item with these files.")
          else ().pure[F]
        ht <- cand.drop(1).traverse(ri => QItem.delete(ctx.store)(ri.id, ri.cid))
        _ <-
          if (ht.sum > 0)
            ctx.logger.warn(s"Removed ${ht.sum} items with same attachments")
          else ().pure[F]
        rms <- OptionT
          .fromOption[F](NonEmptyList.fromList(fileMetaIds.toList))
          .flatMap(fids =>
            OptionT(
              //load attachments but only those mentioned in the task's arguments
              cand.headOption.traverse(ri =>
                ctx.store
                  .transact(RAttachment.findByItemCollectiveSource(ri.id, ri.cid, fids))
                  .flatTap(ats =>
                    ctx.logger.debug(
                      s"Found ${ats.size} attachments. Use only those from task args: $fileMetaIds"
                    )
                  )
              )
            )
          )
          .getOrElse(Vector.empty)
        orig <- rms.traverse(a =>
          ctx.store.transact(RAttachmentSource.findById(a.id)).map(s => (a, s))
        )
        origMap =
          orig
            .map(originFileTuple)
            .toMap
      } yield cand.headOption.map(ri =>
        ItemData(
          ri,
          rms,
          Vector.empty,
          Vector.empty,
          origMap,
          MetaProposalList.empty,
          Nil,
          MetaProposalList.empty,
          Nil
        )
      )
    }

  private def logDifferences[F[_]: Sync](
      ctx: Context[F, ProcessItemArgs],
      saved: Vector[RAttachment],
      saveCount: Int
  ): F[Unit] =
    if (ctx.args.files.size != saved.size)
      ctx.logger.warn(
        s"Not all given files (${ctx.args.files.size}) have been stored. Files retained: ${saved.size}; saveCount=$saveCount"
      )
    else
      ().pure[F]

  private def storeItemError[F[_]: Sync](ctx: Context[F, ProcessItemArgs]): F[Unit] = {
    val msg = "Inserting item failed. DB returned 0 update count!"
    ctx.logger.error(msg) *> Sync[F].raiseError(new Exception(msg))
  }

  //TODO if no source is present, it must be saved!
  private def originFileTuple(
      t: (RAttachment, Option[RAttachmentSource])
  ): (Ident, Ident) =
    t._2.map(s => s.id -> s.fileId).getOrElse(t._1.id -> t._1.fileId)
}
