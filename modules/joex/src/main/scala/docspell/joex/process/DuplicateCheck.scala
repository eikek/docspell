package docspell.joex.process

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.joex.scheduler.{Context, Task}
import docspell.store.queries.QItem
import docspell.store.records.RFileMeta

import bitpeace.FileMeta
import doobie._

object DuplicateCheck {
  type Args = ProcessItemArgs

  def apply[F[_]: Sync]: Task[F, Args, Args] =
    Task { ctx =>
      if (ctx.args.meta.skipDuplicate)
        ctx.logger.debug("Checking for duplicate files") *> removeDuplicates(ctx)
      else ctx.logger.debug("Not checking for duplicates") *> ctx.args.pure[F]
    }

  def removeDuplicates[F[_]: Sync](ctx: Context[F, Args]): F[ProcessItemArgs] =
    for {
      fileMetas <- findDuplicates(ctx)
      _         <- fileMetas.traverse(deleteDuplicate(ctx))
      ids = fileMetas.filter(_.exists).map(_.fm.id).toSet
    } yield ctx.args.copy(files =
      ctx.args.files.filterNot(f => ids.contains(f.fileMetaId.id))
    )

  private def deleteDuplicate[F[_]: Sync](
      ctx: Context[F, Args]
  )(fd: FileMetaDupes): F[Unit] = {
    val fname = ctx.args.files.find(_.fileMetaId.id == fd.fm.id).flatMap(_.name)
    if (fd.exists)
      ctx.logger
        .info(s"Deleting duplicate file ${fname}!") *> ctx.store.bitpeace
        .delete(fd.fm.id)
        .compile
        .drain
    else ().pure[F]
  }

  private def findDuplicates[F[_]: Sync](
      ctx: Context[F, Args]
  ): F[Vector[FileMetaDupes]] =
    ctx.store.transact(for {
      fileMetas <- RFileMeta.findByIds(ctx.args.files.map(_.fileMetaId))
      dupes     <- fileMetas.traverse(checkDuplicate(ctx))
    } yield dupes)

  private def checkDuplicate[F[_]](
      ctx: Context[F, Args]
  )(fm: FileMeta): ConnectionIO[FileMetaDupes] =
    QItem
      .findByChecksum(fm.checksum, ctx.args.meta.collective)
      .map(v => FileMetaDupes(fm, v.nonEmpty))

  case class FileMetaDupes(fm: FileMeta, exists: Boolean)
}
