package docspell.joex.process

import bitpeace.FileMeta
import cats.implicits._
import cats.effect.Sync
import cats.data.OptionT
import fs2.Stream
import docspell.common._
import docspell.joex.scheduler.{Context, Task}
import docspell.store.queries.QItem
import docspell.store.records.{RAttachment, RAttachmentSource, RItem}

/**
  * Task that creates the item.
  */
object CreateItem {

  def apply[F[_]: Sync]: Task[F, ProcessItemArgs, ItemData] =
    findExisting[F].flatMap {
      case Some(ri) => Task.pure(ri)
      case None     => createNew[F]
    }

  def createNew[F[_]: Sync]: Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      def isValidFile(fm: FileMeta) =
        ctx.args.meta.validFileTypes.isEmpty ||
          ctx.args.meta.validFileTypes.map(_.asString).toSet.contains(fm.mimetype.baseType)

      def fileMetas(itemId: Ident, now: Timestamp) =
        Stream
          .emits(ctx.args.files)
          .flatMap(f => ctx.store.bitpeace.get(f.fileMetaId.id).map(fm => (f, fm)))
          .collect({ case (f, Some(fm)) if isValidFile(fm) => f })
          .zipWithIndex
          .evalMap({
            case (f, index) =>
              Ident
                .randomId[F]
                .map(id => RAttachment(id, itemId, f.fileMetaId, index.toInt, now, f.name))
          })
          .compile
          .toVector

      val item = RItem.newItem[F](
        ctx.args.meta.collective,
        ctx.args.makeSubject,
        ctx.args.meta.sourceAbbrev,
        ctx.args.meta.direction.getOrElse(Direction.Incoming),
        ItemState.Premature
      )

      for {
        _    <- ctx.logger.info(s"Creating new item with ${ctx.args.files.size} attachment(s)")
        time <- Duration.stopTime[F]
        it   <- item
        n    <- ctx.store.transact(RItem.insert(it))
        _    <- if (n != 1) storeItemError[F](ctx) else ().pure[F]
        fm   <- fileMetas(it.id, it.created)
        k    <- fm.traverse(insertAttachment(ctx))
        _    <- logDifferences(ctx, fm, k.sum)
        dur  <- time
        _    <- ctx.logger.info(s"Creating item finished in ${dur.formatExact}")
      } yield ItemData(it, fm, Vector.empty, Vector.empty, fm.map(a => a.id -> a.fileId).toMap)
    }

  def insertAttachment[F[_]: Sync](ctx: Context[F, ProcessItemArgs])(ra: RAttachment): F[Int] = {
    val rs = RAttachmentSource.of(ra)
    ctx.store.transact(for {
      n <- RAttachment.insert(ra)
      _ <- RAttachmentSource.insert(rs)
    } yield n)
  }

  def findExisting[F[_]: Sync]: Task[F, ProcessItemArgs, Option[ItemData]] =
    Task { ctx =>
      for {
        cand <- ctx.store.transact(QItem.findByFileIds(ctx.args.files.map(_.fileMetaId)))
        _ <- if (cand.nonEmpty) ctx.logger.warn("Found existing item with these files.")
        else ().pure[F]
        ht <- cand.drop(1).traverse(ri => QItem.delete(ctx.store)(ri.id, ri.cid))
        _ <- if (ht.sum > 0) ctx.logger.warn(s"Removed ${ht.sum} items with same attachments")
        else ().pure[F]
        rms <- OptionT(
          cand.headOption.traverse(ri =>
            ctx.store.transact(RAttachment.findByItemAndCollective(ri.id, ri.cid))
          )
        ).getOrElse(Vector.empty)
        orig <- rms.traverse(a =>
          ctx.store.transact(RAttachmentSource.findById(a.id)).map(s => (a, s))
        )
        origMap = orig
          .map(originFileTuple)
          .toMap
      } yield cand.headOption.map(ri => ItemData(ri, rms, Vector.empty, Vector.empty, origMap))
    }

  private def logDifferences[F[_]: Sync](
      ctx: Context[F, ProcessItemArgs],
      saved: Vector[RAttachment],
      saveCount: Int
  ): F[Unit] =
    if (ctx.args.files.size != saved.size) {
      ctx.logger.warn(
        s"Not all given files (${ctx.args.files.size}) have been stored. Files retained: ${saved.size}; saveCount=$saveCount"
      )
    } else {
      ().pure[F]
    }

  private def storeItemError[F[_]: Sync](ctx: Context[F, ProcessItemArgs]): F[Unit] = {
    val msg = "Inserting item failed. DB returned 0 update count!"
    ctx.logger.error(msg) *> Sync[F].raiseError(new Exception(msg))
  }

  //TODO if no source is present, it must be saved!
  private def originFileTuple(t: (RAttachment, Option[RAttachmentSource])): (Ident, Ident) =
    t._2.map(s => s.id -> s.fileId).getOrElse(t._1.id -> t._1.fileId)
}
