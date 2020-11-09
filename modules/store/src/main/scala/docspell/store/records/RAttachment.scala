package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.impl._

import bitpeace.FileMeta
import doobie._
import doobie.implicits._

case class RAttachment(
    id: Ident,
    itemId: Ident,
    fileId: Ident,
    position: Int,
    created: Timestamp,
    name: Option[String]
) {}

object RAttachment {

  val table = fr"attachment"

  object Columns {
    val id       = Column("attachid")
    val itemId   = Column("itemid")
    val fileId   = Column("filemetaid")
    val position = Column("position")
    val created  = Column("created")
    val name     = Column("name")
    val all      = List(id, itemId, fileId, position, created, name)
  }
  import Columns._

  def insert(v: RAttachment): ConnectionIO[Int] =
    insertRow(
      table,
      all,
      fr"${v.id},${v.itemId},${v.fileId.id},${v.position},${v.created},${v.name}"
    ).update.run

  def decPositions(iId: Ident, lowerBound: Int, upperBound: Int): ConnectionIO[Int] =
    updateRow(
      table,
      and(itemId.is(iId), position.isGte(lowerBound), position.isLte(upperBound)),
      position.decrement(1)
    ).update.run

  def incPositions(iId: Ident, lowerBound: Int, upperBound: Int): ConnectionIO[Int] =
    updateRow(
      table,
      and(itemId.is(iId), position.isGte(lowerBound), position.isLte(upperBound)),
      position.increment(1)
    ).update.run

  def nextPosition(id: Ident): ConnectionIO[Int] =
    for {
      max <- selectSimple(position.max, table, itemId.is(id)).query[Option[Int]].unique
    } yield max.map(_ + 1).getOrElse(0)

  def updateFileIdAndName(
      attachId: Ident,
      fId: Ident,
      fname: Option[String]
  ): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(attachId),
      commas(fileId.setTo(fId), name.setTo(fname))
    ).update.run

  def updateFileId(
      attachId: Ident,
      fId: Ident
  ): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(attachId),
      fileId.setTo(fId)
    ).update.run

  def updatePosition(attachId: Ident, pos: Int): ConnectionIO[Int] =
    updateRow(table, id.is(attachId), position.setTo(pos)).update.run

  def findById(attachId: Ident): ConnectionIO[Option[RAttachment]] =
    selectSimple(all, table, id.is(attachId)).query[RAttachment].option

  def findMeta(attachId: Ident): ConnectionIO[Option[FileMeta]] = {
    import bitpeace.sql._

    val cols      = RFileMeta.Columns.all.map(_.prefix("m"))
    val aId       = id.prefix("a")
    val aFileMeta = fileId.prefix("a")
    val mId       = RFileMeta.Columns.id.prefix("m")

    val from =
      table ++ fr"a INNER JOIN" ++ RFileMeta.table ++ fr"m ON" ++ aFileMeta.is(mId)
    val cond = aId.is(attachId)

    selectSimple(cols, from, cond).query[FileMeta].option
  }

  def updateName(
      attachId: Ident,
      collective: Ident,
      aname: Option[String]
  ): ConnectionIO[Int] = {
    val update = updateRow(table, id.is(attachId), name.setTo(aname)).update.run
    for {
      exists <- existsByIdAndCollective(attachId, collective)
      n      <- if (exists) update else 0.pure[ConnectionIO]
    } yield n
  }

  def findByIdAndCollective(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachment]] =
    selectSimple(
      all.map(_.prefix("a")),
      table ++ fr"a," ++ RItem.table ++ fr"i",
      and(
        fr"a.itemid = i.itemid",
        id.prefix("a").is(attachId),
        RItem.Columns.cid.prefix("i").is(collective)
      )
    ).query[RAttachment].option

  def findByItem(id: Ident): ConnectionIO[Vector[RAttachment]] =
    selectSimple(all, table, itemId.is(id)).query[RAttachment].to[Vector]

  def existsByIdAndCollective(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Boolean] = {
    val aId   = id.prefix("a")
    val aItem = itemId.prefix("a")
    val iId   = RItem.Columns.id.prefix("i")
    val iColl = RItem.Columns.cid.prefix("i")
    val from =
      table ++ fr"a INNER JOIN" ++ RItem.table ++ fr"i ON" ++ aItem.is(iId)
    val cond = and(iColl.is(collective), aId.is(attachId))
    selectCount(id, from, cond).query[Int].unique.map(_ > 0)
  }

  def findByItemAndCollective(
      id: Ident,
      coll: Ident
  ): ConnectionIO[Vector[RAttachment]] = {
    val q = selectSimple(all.map(_.prefix("a")), table ++ fr"a", Fragment.empty) ++
      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ RItem.Columns.id
        .prefix("i")
        .is(itemId.prefix("a")) ++
      fr"WHERE" ++ and(itemId.prefix("a").is(id), RItem.Columns.cid.prefix("i").is(coll))
    q.query[RAttachment].to[Vector]
  }

  def findByItemCollectiveSource(
      id: Ident,
      coll: Ident,
      fileIds: NonEmptyList[Ident]
  ): ConnectionIO[Vector[RAttachment]] = {

    val iId   = RItem.Columns.id.prefix("i")
    val iColl = RItem.Columns.cid.prefix("i")
    val aItem = Columns.itemId.prefix("a")
    val aId   = Columns.id.prefix("a")
    val aFile = Columns.fileId.prefix("a")
    val sId   = RAttachmentSource.Columns.id.prefix("s")
    val sFile = RAttachmentSource.Columns.fileId.prefix("s")
    val rId   = RAttachmentArchive.Columns.id.prefix("r")
    val rFile = RAttachmentArchive.Columns.fileId.prefix("r")

    val from = table ++ fr"a INNER JOIN" ++
      RItem.table ++ fr"i ON" ++ iId.is(aItem) ++ fr"LEFT JOIN" ++
      RAttachmentSource.table ++ fr"s ON" ++ sId.is(aId) ++ fr"LEFT JOIN" ++
      RAttachmentArchive.table ++ fr"r ON" ++ rId.is(aId)

    val cond = and(
      iId.is(id),
      iColl.is(coll),
      or(aFile.isIn(fileIds), sFile.isIn(fileIds), rFile.isIn(fileIds))
    )

    selectSimple(all.map(_.prefix("a")), from, cond).query[RAttachment].to[Vector]
  }

  def findByItemAndCollectiveWithMeta(
      id: Ident,
      coll: Ident
  ): ConnectionIO[Vector[(RAttachment, FileMeta)]] = {
    import bitpeace.sql._

    val cols      = all.map(_.prefix("a")) ++ RFileMeta.Columns.all.map(_.prefix("m"))
    val afileMeta = fileId.prefix("a")
    val aItem     = itemId.prefix("a")
    val mId       = RFileMeta.Columns.id.prefix("m")
    val iId       = RItem.Columns.id.prefix("i")
    val iColl     = RItem.Columns.cid.prefix("i")

    val from =
      table ++ fr"a INNER JOIN" ++ RFileMeta.table ++ fr"m ON" ++ afileMeta.is(mId) ++
        fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ aItem.is(iId)
    val cond = Seq(aItem.is(id), iColl.is(coll))

    selectSimple(cols, from, and(cond)).query[(RAttachment, FileMeta)].to[Vector]
  }

  def findByItemWithMeta(id: Ident): ConnectionIO[Vector[(RAttachment, FileMeta)]] = {
    import bitpeace.sql._

    val q =
      fr"SELECT a.*,m.* FROM" ++ table ++ fr"a, filemeta m WHERE a.filemetaid = m.id AND a.itemid = $id ORDER BY a.position ASC"
    q.query[(RAttachment, FileMeta)].to[Vector]
  }

  /** Deletes the attachment and its related source and meta records.
    */
  def delete(attachId: Ident): ConnectionIO[Int] =
    for {
      n0 <- RAttachmentMeta.delete(attachId)
      n1 <- RAttachmentSource.delete(attachId)
      n2 <- RAttachmentPreview.delete(attachId)
      n3 <- deleteFrom(table, id.is(attachId)).update.run
    } yield n0 + n1 + n2 + n3

  def findItemId(attachId: Ident): ConnectionIO[Option[Ident]] =
    selectSimple(Seq(itemId), table, id.is(attachId)).query[Ident].option

  def findAll(
      coll: Option[Ident],
      chunkSize: Int
  ): Stream[ConnectionIO, RAttachment] = {
    val aItem = Columns.itemId.prefix("a")
    val iId   = RItem.Columns.id.prefix("i")
    val iColl = RItem.Columns.cid.prefix("i")

    val cols = all.map(_.prefix("a"))

    coll match {
      case Some(cid) =>
        val join = table ++ fr"a INNER JOIN" ++ RItem.table ++ fr"i ON" ++ iId.is(aItem)
        val cond = iColl.is(cid)
        selectSimple(cols, join, cond)
          .query[RAttachment]
          .streamWithChunkSize(chunkSize)
      case None =>
        selectSimple(cols, table, Fragment.empty)
          .query[RAttachment]
          .streamWithChunkSize(chunkSize)
    }
  }

  def findAllWithoutPageCount(chunkSize: Int): Stream[ConnectionIO, RAttachment] = {
    val aId    = Columns.id.prefix("a")
    val mId    = RAttachmentMeta.Columns.id.prefix("m")
    val mPages = RAttachmentMeta.Columns.pages.prefix("m")

    val cols = all.map(_.prefix("a"))
    val join = table ++ fr"a LEFT OUTER JOIN" ++
      RAttachmentMeta.table ++ fr"m ON" ++ aId.is(mId)
    val cond = mPages.isNull

    selectSimple(cols, join, cond)
      .query[RAttachment]
      .streamWithChunkSize(chunkSize)
  }

  def findWithoutPreview(
      coll: Option[Ident],
      chunkSize: Int
  ): Stream[ConnectionIO, RAttachment] = {
    val aId   = Columns.id.prefix("a")
    val aItem = Columns.itemId.prefix("a")
    val pId   = RAttachmentPreview.Columns.id.prefix("p")
    val iId   = RItem.Columns.id.prefix("i")
    val iColl = RItem.Columns.cid.prefix("i")

    val cols = all.map(_.prefix("a"))
    val baseJoin =
      table ++ fr"a LEFT OUTER JOIN" ++
        RAttachmentPreview.table ++ fr"p ON" ++ pId.is(aId)

    val baseCond =
      Seq(pId.isNull)

    coll match {
      case Some(cid) =>
        val join = baseJoin ++ fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ iId.is(aItem)
        val cond = and(baseCond ++ Seq(iColl.is(cid)))
        selectSimple(cols, join, cond)
          .query[RAttachment]
          .streamWithChunkSize(chunkSize)
      case None =>
        selectSimple(cols, baseJoin, and(baseCond))
          .query[RAttachment]
          .streamWithChunkSize(chunkSize)
    }
  }

  def findNonConvertedPdf(
      coll: Option[Ident],
      chunkSize: Int
  ): Stream[ConnectionIO, RAttachment] = {
    val aId     = Columns.id.prefix("a")
    val aItem   = Columns.itemId.prefix("a")
    val aFile   = Columns.fileId.prefix("a")
    val sId     = RAttachmentSource.Columns.id.prefix("s")
    val sFile   = RAttachmentSource.Columns.fileId.prefix("s")
    val iId     = RItem.Columns.id.prefix("i")
    val iColl   = RItem.Columns.cid.prefix("i")
    val mId     = RFileMeta.Columns.id.prefix("m")
    val mType   = RFileMeta.Columns.mimetype.prefix("m")
    val pdfType = "application/pdf%"

    val from = table ++ fr"a INNER JOIN" ++
      RAttachmentSource.table ++ fr"s ON" ++ sId.is(aId) ++ fr"INNER JOIN" ++
      RItem.table ++ fr"i ON" ++ iId.is(aItem) ++ fr"INNER JOIN" ++
      RFileMeta.table ++ fr"m ON" ++ aFile.is(mId)
    val where = coll match {
      case Some(cid) => and(iColl.is(cid), aFile.is(sFile), mType.lowerLike(pdfType))
      case None      => and(aFile.is(sFile), mType.lowerLike(pdfType))
    }
    selectSimple(all.map(_.prefix("a")), from, where)
      .query[RAttachment]
      .streamWithChunkSize(chunkSize)
  }
}
