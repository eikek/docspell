package docspell.joex.process

import cats.implicits._
import cats.effect.Sync
import fs2.Stream
import docspell.common._
import docspell.joex.scheduler.{Context, Task}
import docspell.store.queries.QItem
import docspell.store.records.{RAttachment, RItem}

/**
  * Task that creates the item.
  */
object CreateItem {

  def apply[F[_]: Sync]: Task[F, ProcessItemArgs, ItemData] =
    findExisting[F].flatMap {
      case Some(ri) => Task.pure(ri)
      case None => createNew[F]
    }

  def createNew[F[_]: Sync]: Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      val validFiles = ctx.args.meta.validFileTypes.map(_.asString).toSet

      def fileMetas(itemId: Ident, now: Timestamp) = Stream.emits(ctx.args.files).
        flatMap(f => ctx.store.bitpeace.get(f.fileMetaId.id).map(fm => (f, fm))).
        collect({ case (f, Some(fm)) if validFiles.contains(fm.mimetype.baseType) => f }).
        zipWithIndex.
        evalMap({ case (f, index) =>
            Ident.randomId[F].map(id => RAttachment(id, itemId, f.fileMetaId, index.toInt, now, f.name))
        }).
        compile.toVector

      val item = RItem.newItem[F](ctx.args.meta.collective
        , ctx.args.makeSubject
        , ctx.args.meta.sourceAbbrev
        , ctx.args.meta.direction.getOrElse(Direction.Incoming)
        , ItemState.Premature)

      for {
        _  <- ctx.logger.info(s"Creating new item with ${ctx.args.files.size} attachment(s)")
        time <- Duration.stopTime[F]
        it <- item
        n  <- ctx.store.transact(RItem.insert(it))
        _  <- if (n != 1) storeItemError[F](ctx) else ().pure[F]
        fm <- fileMetas(it.id, it.created)
        k  <- fm.traverse(a => ctx.store.transact(RAttachment.insert(a)))
        _  <- logDifferences(ctx, fm, k.sum)
        dur <- time
        _  <- ctx.logger.info(s"Creating item finished in ${dur.formatExact}")
      } yield ItemData(it, fm, Vector.empty, Vector.empty)
    }

  def findExisting[F[_]: Sync]: Task[F, ProcessItemArgs, Option[ItemData]] =
    Task { ctx =>
      for {
        cand  <- ctx.store.transact(QItem.findByFileIds(ctx.args.files.map(_.fileMetaId)))
        _     <- if (cand.nonEmpty) ctx.logger.warn("Found existing item with these files.") else ().pure[F]
        ht    <- cand.drop(1).traverse(ri => QItem.delete(ctx.store)(ri.id, ri.cid))
        _     <- if (ht.sum > 0) ctx.logger.warn(s"Removed ${ht.sum} items with same attachments") else ().pure[F]
        rms   <- cand.headOption.traverse(ri => ctx.store.transact(RAttachment.findByItemAndCollective(ri.id, ri.cid)))
      } yield cand.headOption.map(ri => ItemData(ri, rms.getOrElse(Vector.empty), Vector.empty, Vector.empty))
    }

  private def logDifferences[F[_]: Sync](ctx: Context[F, ProcessItemArgs], saved: Vector[RAttachment], saveCount: Int): F[Unit] =
    if (ctx.args.files.size != saved.size) {
      ctx.logger.warn(s"Not all given files (${ctx.args.files.size}) have been stored. Files retained: ${saved.size}; saveCount=$saveCount")
    } else {
      ().pure[F]
    }

  private def storeItemError[F[_]: Sync](ctx: Context[F, ProcessItemArgs]): F[Unit] = {
    val msg = "Inserting item failed. DB returned 0 update count!"
    ctx.logger.error(msg) *> Sync[F].raiseError(new Exception(msg))
  }
}
