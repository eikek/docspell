package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb.TableDef
import docspell.store.qb._

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
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "attachment"

    val id       = Column[Ident]("attachid", this)
    val itemId   = Column[Ident]("itemid", this)
    val fileId   = Column[Ident]("filemetaid", this)
    val position = Column[Int]("position", this)
    val created  = Column[Timestamp]("created", this)
    val name     = Column[String]("name", this)
    val all      = NonEmptyList.of[Column[_]](id, itemId, fileId, position, created, name)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  val table = fr"attachment"

  object Columns {
    import docspell.store.impl._

    val id       = Column("attachid")
    val itemId   = Column("itemid")
    val fileId   = Column("filemetaid")
    val position = Column("position")
    val created  = Column("created")
    val name     = Column("name")
    val all      = List(id, itemId, fileId, position, created, name)
  }

  def insert(v: RAttachment): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.id},${v.itemId},${v.fileId.id},${v.position},${v.created},${v.name}"
    )

  def decPositions(iId: Ident, lowerBound: Int, upperBound: Int): ConnectionIO[Int] =
    DML.update(
      T,
      where(
        T.itemId === iId && T.position >= lowerBound && T.position <= upperBound
      ),
      DML.set(T.position.decrement(1))
    )

  def incPositions(iId: Ident, lowerBound: Int, upperBound: Int): ConnectionIO[Int] =
    DML.update(
      T,
      where(
        T.itemId === iId && T.position >= lowerBound && T.position <= upperBound
      ),
      DML.set(T.position.increment(1))
    )

  def nextPosition(id: Ident): ConnectionIO[Int] =
    for {
      max <- Select(max(T.position).s, from(T), T.itemId === id).build
        .query[Option[Int]]
        .unique
    } yield max.map(_ + 1).getOrElse(0)

  def updateFileIdAndName(
      attachId: Ident,
      fId: Ident,
      fname: Option[String]
  ): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === attachId,
      DML.set(T.fileId.setTo(fId), T.name.setTo(fname))
    )

  def updateFileId(
      attachId: Ident,
      fId: Ident
  ): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === attachId,
      DML.set(T.fileId.setTo(fId))
    )

  def updatePosition(attachId: Ident, pos: Int): ConnectionIO[Int] =
    DML.update(T, T.id === attachId, DML.set(T.position.setTo(pos)))

  def findById(attachId: Ident): ConnectionIO[Option[RAttachment]] =
    run(select(T.all), from(T), T.id === attachId).query[RAttachment].option

  def findMeta(attachId: Ident): ConnectionIO[Option[FileMeta]] = {
    import bitpeace.sql._

//    val cols      = RFileMeta.Columns.all.map(_.prefix("m"))
//    val aId       = id.prefix("a")
//    val aFileMeta = fileId.prefix("a")
//    val mId       = RFileMeta.Columns.id.prefix("m")
//
//    val from =
//      table ++ fr"a INNER JOIN" ++ RFileMeta.table ++ fr"m ON" ++ aFileMeta.is(mId)
//    val cond = aId.is(attachId)
//
//    selectSimple(cols, from, cond).query[FileMeta].option
    val m = RFileMeta.as("m")
    val a = RAttachment.as("a")
    Select(
      select(m.all),
      from(a)
        .innerJoin(m, a.fileId === m.id),
      a.id === attachId
    ).build.query[FileMeta].option
  }

  def updateName(
      attachId: Ident,
      collective: Ident,
      aname: Option[String]
  ): ConnectionIO[Int] = {
    val update = DML.update(T, T.id === attachId, DML.set(T.name.setTo(aname)))
    for {
      exists <- existsByIdAndCollective(attachId, collective)
      n      <- if (exists) update else 0.pure[ConnectionIO]
    } yield n
  }

  def findByIdAndCollective(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachment]] = {
    val a = RAttachment.as("a")
    val i = RItem.as("i")
    Select(
      select(a.all),
      from(a).innerJoin(i, a.itemId === i.id),
      a.id === attachId && i.cid === collective
    ).build.query[RAttachment].option
  }

  def findByItem(id: Ident): ConnectionIO[Vector[RAttachment]] =
    run(select(T.all), from(T), T.itemId === id).query[RAttachment].to[Vector]

  def existsByIdAndCollective(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Boolean] = {
//    val aId   = id.prefix("a")
//    val aItem = itemId.prefix("a")
//    val iId   = RItem.Columns.id.prefix("i")
//    val iColl = RItem.Columns.cid.prefix("i")
//    val from =
//      table ++ fr"a INNER JOIN" ++ RItem.table ++ fr"i ON" ++ aItem.is(iId)
//    val cond = and(iColl.is(collective), aId.is(attachId))
//    selectCount(id, from, cond).query[Int].unique.map(_ > 0)
    val a = RAttachment.as("a")
    val i = RItem.as("i")
    Select(
      count(a.id).s,
      from(a)
        .innerJoin(i, a.itemId === i.id),
      i.cid === collective && a.id === attachId
    ).build.query[Int].unique.map(_ > 0)
  }

  def findByItemAndCollective(
      id: Ident,
      coll: Ident
  ): ConnectionIO[Vector[RAttachment]] = {
//    val q = selectSimple(all.map(_.prefix("a")), table ++ fr"a", Fragment.empty) ++
//      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ RItem.Columns.id
//        .prefix("i")
//        .is(itemId.prefix("a")) ++
//      fr"WHERE" ++ and(itemId.prefix("a").is(id), RItem.Columns.cid.prefix("i").is(coll))
//    q.query[RAttachment].to[Vector]
    val a = RAttachment.as("a")
    val i = RItem.as("i")
    Select(
      select(a.all),
      from(a)
        .innerJoin(i, i.id === a.itemId),
      a.itemId === id && i.cid === coll
    ).build.query[RAttachment].to[Vector]
  }

  def findByItemCollectiveSource(
      id: Ident,
      coll: Ident,
      fileIds: NonEmptyList[Ident]
  ): ConnectionIO[Vector[RAttachment]] = {

//    val iId   = RItem.Columns.id.prefix("i")
//    val iColl = RItem.Columns.cid.prefix("i")
//    val aItem = Columns.itemId.prefix("a")
//    val aId   = Columns.id.prefix("a")
//    val aFile = Columns.fileId.prefix("a")
//    val sId   = RAttachmentSource.Columns.id.prefix("s")
//    val sFile = RAttachmentSource.Columns.fileId.prefix("s")
//    val rId   = RAttachmentArchive.Columns.id.prefix("r")
//    val rFile = RAttachmentArchive.Columns.fileId.prefix("r")
//
//    val from = table ++ fr"a INNER JOIN" ++
//      RItem.table ++ fr"i ON" ++ iId.is(aItem) ++ fr"LEFT JOIN" ++
//      RAttachmentSource.table ++ fr"s ON" ++ sId.is(aId) ++ fr"LEFT JOIN" ++
//      RAttachmentArchive.table ++ fr"r ON" ++ rId.is(aId)
//
//    val cond = and(
//      iId.is(id),
//      iColl.is(coll),
//      or(aFile.isIn(fileIds), sFile.isIn(fileIds), rFile.isIn(fileIds))
//    )
//
//    selectSimple(all.map(_.prefix("a")), from, cond).query[RAttachment].to[Vector]
    val i = RItem.as("i")
    val a = RAttachment.as("a")
    val s = RAttachmentSource.as("s")
    val r = RAttachmentArchive.as("r")

    Select(
      select(a.all),
      from(a)
        .innerJoin(i, i.id === a.itemId)
        .leftJoin(s, s.id === a.id)
        .leftJoin(r, r.id === a.id),
      i.id === id && i.cid === coll &&
        (a.fileId.in(fileIds) || s.fileId.in(fileIds) || r.fileId.in(fileIds))
    ).build.query[RAttachment].to[Vector]
  }

  def findByItemAndCollectiveWithMeta(
      id: Ident,
      coll: Ident
  ): ConnectionIO[Vector[(RAttachment, FileMeta)]] = {
    import bitpeace.sql._

//    val cols      = all.map(_.prefix("a")) ++ RFileMeta.Columns.all.map(_.prefix("m"))
//    val afileMeta = fileId.prefix("a")
//    val aItem     = itemId.prefix("a")
//    val mId       = RFileMeta.Columns.id.prefix("m")
//    val iId       = RItem.Columns.id.prefix("i")
//    val iColl     = RItem.Columns.cid.prefix("i")
//
//    val from =
//      table ++ fr"a INNER JOIN" ++ RFileMeta.table ++ fr"m ON" ++ afileMeta.is(mId) ++
//        fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ aItem.is(iId)
//    val cond = Seq(aItem.is(id), iColl.is(coll))
//
//    selectSimple(cols, from, and(cond)).query[(RAttachment, FileMeta)].to[Vector]
    val a = RAttachment.as("a")
    val m = RFileMeta.as("m")
    val i = RItem.as("i")
    Select(
      select(a.all, m.all),
      from(a)
        .innerJoin(m, a.fileId === m.id)
        .innerJoin(i, a.itemId === i.id),
      a.itemId === id && i.cid === coll
    ).build.query[(RAttachment, FileMeta)].to[Vector]
  }

  def findByItemWithMeta(id: Ident): ConnectionIO[Vector[(RAttachment, FileMeta)]] = {
    import bitpeace.sql._

//    val q =
//      fr"SELECT a.*,m.* FROM" ++ table ++ fr"a, filzemeta m
//      WHERE a.filemetaid = m.id AND a.itemid = $id ORDER BY a.position ASC"
    val a = RAttachment.as("a")
    val m = RFileMeta.as("m")
    Select(
      select(a.all, m.all),
      from(a)
        .innerJoin(m, a.fileId === m.id),
      a.itemId === id
    ).orderBy(a.position.asc).build.query[(RAttachment, FileMeta)].to[Vector]
  }

  /** Deletes the attachment and its related source and meta records.
    */
  def delete(attachId: Ident): ConnectionIO[Int] =
    for {
      n0 <- RAttachmentMeta.delete(attachId)
      n1 <- RAttachmentSource.delete(attachId)
      n2 <- RAttachmentPreview.delete(attachId)
      n3 <- DML.delete(T, T.id === attachId)
    } yield n0 + n1 + n2 + n3

  def findItemId(attachId: Ident): ConnectionIO[Option[Ident]] =
    Select(T.itemId.s, from(T), T.id === attachId).build.query[Ident].option

  def findAll(
      coll: Option[Ident],
      chunkSize: Int
  ): Stream[ConnectionIO, RAttachment] = {
//    val aItem = Columns.itemId.prefix("a")
//    val iId   = RItem.Columns.id.prefix("i")
//    val iColl = RItem.Columns.cid.prefix("i")
//
//    val cols = all.map(_.prefix("a"))
//
//    coll match {
//      case Some(cid) =>
//        val join = table ++ fr"a INNER JOIN" ++ RItem.table ++ fr"i ON" ++ iId.is(aItem)
//        val cond = iColl.is(cid)
//        selectSimple(cols, join, cond)
//          .query[RAttachment]
//          .streamWithChunkSize(chunkSize)
//      case None =>
//        selectSimple(cols, table, Fragment.empty)
//          .query[RAttachment]
//          .streamWithChunkSize(chunkSize)
//    }
    val a = RAttachment.as("a")
    val i = RItem.as("i")

    coll match {
      case Some(cid) =>
        Select(
          select(a.all),
          from(a)
            .innerJoin(i, i.id === a.itemId),
          i.cid === cid
        ).build.query[RAttachment].streamWithChunkSize(chunkSize)
      case None =>
        Select(select(a.all), from(a)).build
          .query[RAttachment]
          .streamWithChunkSize(chunkSize)
    }
  }

  def findAllWithoutPageCount(chunkSize: Int): Stream[ConnectionIO, RAttachment] = {
//    val aId      = Columns.id.prefix("a")
//    val aCreated = Columns.created.prefix("a")
//    val mId      = RAttachmentMeta.Columns.id.prefix("m")
//    val mPages   = RAttachmentMeta.Columns.pages.prefix("m")
//
//    val cols = all.map(_.prefix("a"))
//    val join = table ++ fr"a LEFT OUTER JOIN" ++
//      RAttachmentMeta.table ++ fr"m ON" ++ aId.is(mId)
//    val cond = mPages.isNull
//
//    (selectSimple(cols, join, cond) ++ orderBy(aCreated.desc))
//      .query[RAttachment]
//      .streamWithChunkSize(chunkSize)
    val a = RAttachment.as("a")
    val m = RAttachmentMeta.as("m")
    Select(
      select(a.all),
      from(a)
        .leftJoin(m, a.id === m.id),
      m.pages.isNull
    ).build.query[RAttachment].streamWithChunkSize(chunkSize)
  }

  def findWithoutPreview(
      coll: Option[Ident],
      chunkSize: Int
  ): Stream[ConnectionIO, RAttachment] = {
//    val aId      = Columns.id.prefix("a")
//    val aItem    = Columns.itemId.prefix("a")
//    val aCreated = Columns.created.prefix("a")
//    val pId      = RAttachmentPreview.Columns.id.prefix("p")
//    val iId      = RItem.Columns.id.prefix("i")
//    val iColl    = RItem.Columns.cid.prefix("i")
//
//    val cols = all.map(_.prefix("a"))
//    val baseJoin =
//      table ++ fr"a LEFT OUTER JOIN" ++
//        RAttachmentPreview.table ++ fr"p ON" ++ pId.is(aId)
//
//    val baseCond =
//      Seq(pId.isNull)
//
//    coll match {
//      case Some(cid) =>
//        val join = baseJoin ++ fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ iId.is(aItem)
//        val cond = and(baseCond ++ Seq(iColl.is(cid)))
//        (selectSimple(cols, join, cond) ++ orderBy(aCreated.desc))
//          .query[RAttachment]
//          .streamWithChunkSize(chunkSize)
//      case None =>
//        (selectSimple(cols, baseJoin, and(baseCond)) ++ orderBy(aCreated.desc))
//          .query[RAttachment]
//          .streamWithChunkSize(chunkSize)
//    }
    val a = RAttachment.as("a")
    val p = RAttachmentPreview.as("p")
    val i = RItem.as("i")

    val baseJoin = from(a).leftJoin(p, p.id === a.id)
    Select(
      select(a.all),
      coll.map(_ => baseJoin.innerJoin(i, i.id === a.itemId)).getOrElse(baseJoin),
      p.id.isNull &&? coll.map(cid => i.cid === cid)
    ).orderBy(a.created.asc).build.query[RAttachment].streamWithChunkSize(chunkSize)
  }

  def findNonConvertedPdf(
      coll: Option[Ident],
      chunkSize: Int
  ): Stream[ConnectionIO, RAttachment] = {
//    val aId     = Columns.id.prefix("a")
//    val aItem   = Columns.itemId.prefix("a")
//    val aFile   = Columns.fileId.prefix("a")
//    val sId     = RAttachmentSource.Columns.id.prefix("s")
//    val sFile   = RAttachmentSource.Columns.fileId.prefix("s")
//    val iId     = RItem.Columns.id.prefix("i")
//    val iColl   = RItem.Columns.cid.prefix("i")
//    val mId     = RFileMeta.Columns.id.prefix("m")
//    val mType   = RFileMeta.Columns.mimetype.prefix("m")
    val pdfType = "application/pdf%"
//
//    val from = table ++ fr"a INNER JOIN" ++
//      RAttachmentSource.table ++ fr"s ON" ++ sId.is(aId) ++ fr"INNER JOIN" ++
//      RItem.table ++ fr"i ON" ++ iId.is(aItem) ++ fr"INNER JOIN" ++
//      RFileMeta.table ++ fr"m ON" ++ aFile.is(mId)
//    val where = coll match {
//      case Some(cid) => and(iColl.is(cid), aFile.is(sFile), mType.lowerLike(pdfType))
//      case None      => and(aFile.is(sFile), mType.lowerLike(pdfType))
//    }
//    selectSimple(all.map(_.prefix("a")), from, where)
//      .query[RAttachment]
//      .streamWithChunkSize(chunkSize)
    val a = RAttachment.as("a")
    val s = RAttachmentSource.as("s")
    val i = RItem.as("i")
    val m = RFileMeta.as("m")

    Select(
      select(a.all),
      from(a)
        .innerJoin(s, s.id === a.id)
        .innerJoin(i, i.id === a.itemId)
        .innerJoin(m, m.id === a.fileId),
      a.fileId === s.fileId &&
        m.mimetype.likes(pdfType) &&?
        coll.map(cid => i.cid === cid)
    ).build.query[RAttachment].streamWithChunkSize(chunkSize)
  }
}
