package docspell.store.queries

import fs2.Stream
import cats.implicits._
import cats.effect.Sync
import doobie._
import doobie.implicits._
import docspell.common.{Ident, MetaProposalList}
import docspell.store.Store
import docspell.store.impl.Implicits._
import docspell.store.records.{RAttachment, RAttachmentMeta, RItem}

object QAttachment {

  def deleteById[F[_]: Sync](store: Store[F])(attachId: Ident, coll: Ident): F[Int] =
    for {
      raOpt <- store.transact(RAttachment.findByIdAndCollective(attachId, coll))
      n     <- raOpt.traverse(_ => store.transact(RAttachment.delete(attachId)))
      f <- Stream
            .emit(raOpt)
            .unNoneTerminate
            .map(_.fileId.id)
            .flatMap(store.bitpeace.delete)
            .compile
            .last
    } yield n.getOrElse(0) + f.map(_ => 1).getOrElse(0)

  def deleteAttachment[F[_]: Sync](store: Store[F])(ra: RAttachment): F[Int] =
    for {
      n <- store.transact(RAttachment.delete(ra.id))
      f <- Stream.emit(ra.fileId.id).flatMap(store.bitpeace.delete).compile.last
    } yield n + f.map(_ => 1).getOrElse(0)

  def deleteItemAttachments[F[_]: Sync](store: Store[F])(itemId: Ident, coll: Ident): F[Int] =
    for {
      ras <- store.transact(RAttachment.findByItemAndCollective(itemId, coll))
      ns  <- ras.traverse(deleteAttachment[F](store))
    } yield ns.sum

  def getMetaProposals(itemId: Ident, coll: Ident): ConnectionIO[MetaProposalList] = {
    val AC = RAttachment.Columns
    val MC = RAttachmentMeta.Columns
    val IC = RItem.Columns

    val q = fr"SELECT" ++ MC.proposals
      .prefix("m")
      .f ++ fr"FROM" ++ RAttachmentMeta.table ++ fr"m" ++
      fr"INNER JOIN" ++ RAttachment.table ++ fr"a ON" ++ AC.id.prefix("a").is(MC.id.prefix("m")) ++
      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ AC.itemId.prefix("a").is(IC.id.prefix("i")) ++
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

    val q = fr"SELECT" ++ commas(MC.all.map(_.prefix("m").f)) ++ fr"FROM" ++ RItem.table ++ fr"i" ++
      fr"INNER JOIN" ++ RAttachment.table ++ fr"a ON" ++ IC.id
      .prefix("i")
      .is(AC.itemId.prefix("a")) ++
      fr"INNER JOIN" ++ RAttachmentMeta.table ++ fr"m ON" ++ AC.id
      .prefix("a")
      .is(MC.id.prefix("m")) ++
      fr"WHERE" ++ and(AC.id.prefix("a").is(attachId), IC.cid.prefix("i").is(collective))

    q.query[RAttachmentMeta].option
  }
}
