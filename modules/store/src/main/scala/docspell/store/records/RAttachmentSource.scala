package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import bitpeace.FileMeta
import doobie._
import doobie.implicits._

/** The origin file of an attachment. The `id` is shared with the
  * attachment, to create a 1-1 (or 0..1-1) relationship.
  */
case class RAttachmentSource(
    id: Ident, //same as RAttachment.id
    fileId: Ident,
    name: Option[String],
    created: Timestamp
)

object RAttachmentSource {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "attachment_source"

    val id      = Column[Ident]("id", this)
    val fileId  = Column[Ident]("file_id", this)
    val name    = Column[String]("filename", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, fileId, name, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  val table = fr"attachment_source"
  object Columns {
    import docspell.store.impl._
    val id      = Column("id")
    val fileId  = Column("file_id")
    val name    = Column("filename")
    val created = Column("created")

    val all = List(id, fileId, name, created)
  }

  def of(ra: RAttachment): RAttachmentSource =
    RAttachmentSource(ra.id, ra.fileId, ra.name, ra.created)

  def insert(v: RAttachmentSource): ConnectionIO[Int] =
    DML.insert(T, T.all, fr"${v.id},${v.fileId},${v.name},${v.created}")

  def findById(attachId: Ident): ConnectionIO[Option[RAttachmentSource]] =
    run(select(T.all), from(T), T.id === attachId).query[RAttachmentSource].option

  def isSameFile(attachId: Ident, file: Ident): ConnectionIO[Boolean] =
    Select(count(T.id).s, from(T), T.id === attachId && T.fileId === file).build
      .query[Int]
      .unique
      .map(_ > 0)

  def isConverted(attachId: Ident): ConnectionIO[Boolean] = {
    val s = RAttachmentSource.as("s")
    val a = RAttachment.as("a")
    Select(
      count(a.id).s,
      from(s).innerJoin(a, a.id === s.id),
      a.id === attachId && a.fileId <> s.fileId
    ).build.query[Int].unique.map(_ > 0)

//    val sId   = Columns.id.prefix("s")
//    val sFile = Columns.fileId.prefix("s")
//    val aId   = RAttachment.Columns.id.prefix("a")
//    val aFile = RAttachment.Columns.fileId.prefix("a")
//
//    val from = table ++ fr"s INNER JOIN" ++
//      RAttachment.table ++ fr"a ON" ++ aId.is(sId)
//
//    selectCount(aId, from, and(aId.is(attachId), aFile.isNot(sFile)))
//      .query[Int]
//      .unique
//      .map(_ > 0)
  }

  def delete(attachId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === attachId)

  def findByIdAndCollective(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachmentSource]] = {
//    val bId   = RAttachment.Columns.id.prefix("b")
//    val aId   = Columns.id.prefix("a")
//    val bItem = RAttachment.Columns.itemId.prefix("b")
//    val iId   = RItem.Columns.id.prefix("i")
//    val iColl = RItem.Columns.cid.prefix("i")
//
//    val from = table ++ fr"a INNER JOIN" ++
//      RAttachment.table ++ fr"b ON" ++ aId.is(bId) ++
//      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ bItem.is(iId)
//
//    val where = and(aId.is(attachId), bId.is(attachId), iColl.is(collective))
//
//    selectSimple(all.map(_.prefix("a")), from, where).query[RAttachmentSource].option
    val b = RAttachment.as("b")
    val a = RAttachmentSource.as("a")
    val i = RItem.as("i")

    Select(
      select(a.all),
      from(a)
        .innerJoin(b, a.id === b.id)
        .innerJoin(i, i.id === b.itemId),
      a.id === attachId && b.id === attachId && i.cid === collective
    ).build.query[RAttachmentSource].option
  }

  def findByItem(itemId: Ident): ConnectionIO[Vector[RAttachmentSource]] = {
//    val sId   = Columns.id.prefix("s")
//    val aId   = RAttachment.Columns.id.prefix("a")
//    val aItem = RAttachment.Columns.itemId.prefix("a")
//
//    val from = table ++ fr"s INNER JOIN" ++ RAttachment.table ++ fr"a ON" ++ sId.is(aId)
//    selectSimple(all.map(_.prefix("s")), from, aItem.is(itemId))
//      .query[RAttachmentSource]
//      .to[Vector]

    val s = RAttachmentSource.as("s")
    val a = RAttachment.as("a")
    Select(select(s.all), from(s).innerJoin(a, a.id === s.id), a.itemId === itemId).build
      .query[RAttachmentSource]
      .to[Vector]
  }

  def findByItemWithMeta(
      id: Ident
  ): ConnectionIO[Vector[(RAttachmentSource, FileMeta)]] = {
    import bitpeace.sql._

//    val aId       = Columns.id.prefix("a")
//    val afileMeta = fileId.prefix("a")
//    val bPos      = RAttachment.Columns.position.prefix("b")
//    val bId       = RAttachment.Columns.id.prefix("b")
//    val bItem     = RAttachment.Columns.itemId.prefix("b")
//    val mId       = RFileMeta.Columns.id.prefix("m")
//
//    val cols = all.map(_.prefix("a")) ++ RFileMeta.Columns.all.map(_.prefix("m"))
//    val from = table ++ fr"a INNER JOIN" ++
//      RFileMeta.table ++ fr"m ON" ++ afileMeta.is(mId) ++ fr"INNER JOIN" ++
//      RAttachment.table ++ fr"b ON" ++ aId.is(bId)
//    val where = bItem.is(id)
//
//    (selectSimple(cols, from, where) ++ orderBy(bPos.asc))
//      .query[(RAttachmentSource, FileMeta)]
//      .to[Vector]
    val a = RAttachmentSource.as("a")
    val b = RAttachment.as("b")
    val m = RFileMeta.as("m")

    Select(
      select(a.all, m.all),
      from(a)
        .innerJoin(m, a.fileId === m.id)
        .innerJoin(b, b.id === a.id),
      b.itemId === id
    ).orderBy(b.position.asc).build.query[(RAttachmentSource, FileMeta)].to[Vector]
  }

}
