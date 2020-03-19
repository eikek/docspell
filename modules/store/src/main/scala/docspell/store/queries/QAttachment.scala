package docspell.store.queries

import fs2.Stream
import cats.implicits._
import cats.effect.Sync
import cats.data.OptionT
import doobie._
import doobie.implicits._
import docspell.common.{Ident, MetaProposalList}
import docspell.store.Store
import docspell.store.impl.Implicits._
import docspell.store.records._
import docspell.common.syntax.all._

object QAttachment {
  private[this] val logger = org.log4s.getLogger

  def deleteById[F[_]: Sync](store: Store[F])(attachId: Ident, coll: Ident): F[Int] =
    for {
      raFile <- store
        .transact(RAttachment.findByIdAndCollective(attachId, coll))
        .map(_.map(_.fileId))
      rsFile <- store
        .transact(RAttachmentSource.findByIdAndCollective(attachId, coll))
        .map(_.map(_.fileId))
      aaFile <- store
        .transact(RAttachmentArchive.findByIdAndCollective(attachId, coll))
        .map(_.map(_.fileId))
      n <- store.transact(RAttachment.delete(attachId))
      f <- Stream
        .emits(raFile.toSeq ++ rsFile.toSeq ++ aaFile.toSeq)
        .map(_.id)
        .flatMap(store.bitpeace.delete)
        .map(flag => if (flag) 1 else 0)
        .compile
        .foldMonoid
    } yield n + f

  def deleteAttachment[F[_]: Sync](store: Store[F])(ra: RAttachment): F[Int] =
    for {
      _ <- logger.fdebug[F](s"Deleting attachment: ${ra.id.id}")
      s <- store.transact(RAttachmentSource.findById(ra.id))
      n <- store.transact(RAttachment.delete(ra.id))
      _ <- logger.fdebug[F](
        s"Deleted $n meta records (source, meta, archive). Deleting binaries now."
      )
      f <- Stream
        .emits(ra.fileId.id +: (s.map(_.fileId.id).toSeq))
        .flatMap(store.bitpeace.delete)
        .map(flag => if (flag) 1 else 0)
        .compile
        .foldMonoid
    } yield n + f

  def deleteArchive[F[_]: Sync](store: Store[F])(attachId: Ident): F[Int] = {
    (for {
      aa <- OptionT(store.transact(RAttachmentArchive.findById(attachId)))
      n  <- OptionT.liftF(store.transact(RAttachmentArchive.deleteAll(aa.fileId)))
      _ <- OptionT.liftF(
        Stream
          .emit(aa.fileId.id)
          .flatMap(store.bitpeace.delete)
          .compile
          .drain
      )
    } yield n).getOrElse(0)
  }

  def deleteItemAttachments[F[_]: Sync](
      store: Store[F]
  )(itemId: Ident, coll: Ident): F[Int] =
    for {
      ras <- store.transact(RAttachment.findByItemAndCollective(itemId, coll))
      _ <- logger.finfo[F](
        s"Have ${ras.size} attachments to delete. Must first delete archive entries"
      )
      a  <- ras.traverse(a => deleteArchive(store)(a.id))
      _  <- logger.fdebug[F](s"Deleted ${a.sum} archive entries")
      ns <- ras.traverse(deleteAttachment[F](store))
    } yield ns.sum

  def getMetaProposals(itemId: Ident, coll: Ident): ConnectionIO[MetaProposalList] = {
    val AC = RAttachment.Columns
    val MC = RAttachmentMeta.Columns
    val IC = RItem.Columns

    val q = fr"SELECT" ++ MC.proposals
      .prefix("m")
      .f ++ fr"FROM" ++ RAttachmentMeta.table ++ fr"m" ++
      fr"INNER JOIN" ++ RAttachment.table ++ fr"a ON" ++ AC.id
      .prefix("a")
      .is(MC.id.prefix("m")) ++
      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ AC.itemId
      .prefix("a")
      .is(IC.id.prefix("i")) ++
      fr"WHERE" ++ and(AC.itemId.prefix("a").is(itemId), IC.cid.prefix("i").is(coll))

    for {
      ml <- q.query[MetaProposalList].to[Vector]
    } yield MetaProposalList.flatten(ml)
  }

  def getAttachmentMeta(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachmentMeta]] = {
    val AC = RAttachment.Columns
    val MC = RAttachmentMeta.Columns
    val IC = RItem.Columns

    val q =
      fr"SELECT" ++ commas(MC.all.map(_.prefix("m").f)) ++ fr"FROM" ++ RItem.table ++ fr"i" ++
        fr"INNER JOIN" ++ RAttachment.table ++ fr"a ON" ++ IC.id
        .prefix("i")
        .is(AC.itemId.prefix("a")) ++
        fr"INNER JOIN" ++ RAttachmentMeta.table ++ fr"m ON" ++ AC.id
        .prefix("a")
        .is(MC.id.prefix("m")) ++
        fr"WHERE" ++ and(
        AC.id.prefix("a").is(attachId),
        IC.cid.prefix("i").is(collective)
      )

    q.query[RAttachmentMeta].option
  }
}
