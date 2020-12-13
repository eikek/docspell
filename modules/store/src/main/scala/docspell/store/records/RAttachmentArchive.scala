package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb.TableDef
import docspell.store.qb._

import bitpeace.FileMeta
import doobie._
import doobie.implicits._

/** The archive file of some attachment. The `id` is shared with the
  * attachment, to create a 0..1-1 relationship.
  */
case class RAttachmentArchive(
    id: Ident, //same as RAttachment.id
    fileId: Ident,
    name: Option[String],
    messageId: Option[String],
    created: Timestamp
)

object RAttachmentArchive {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "attachment_archive"

    val id        = Column[Ident]("id", this)
    val fileId    = Column[Ident]("file_id", this)
    val name      = Column[String]("filename", this)
    val messageId = Column[String]("message_id", this)
    val created   = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, fileId, name, messageId, created)
  }
  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  val table = fr"attachment_archive"
  object Columns {
    import docspell.store.impl._

    val id        = Column("id")
    val fileId    = Column("file_id")
    val name      = Column("filename")
    val messageId = Column("message_id")
    val created   = Column("created")

    val all = List(id, fileId, name, messageId, created)
  }

  def of(ra: RAttachment, mId: Option[String]): RAttachmentArchive =
    RAttachmentArchive(ra.id, ra.fileId, ra.name, mId, ra.created)

  def insert(v: RAttachmentArchive): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.id},${v.fileId},${v.name},${v.messageId},${v.created}"
    )

  def findById(attachId: Ident): ConnectionIO[Option[RAttachmentArchive]] =
    run(select(T.all), from(T), T.id === attachId).query[RAttachmentArchive].option

  def delete(attachId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === attachId)

  def deleteAll(fId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.fileId === fId)

  def findByIdAndCollective(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachmentArchive]] = {
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
//    selectSimple(all.map(_.prefix("a")), from, where).query[RAttachmentArchive].option
    val b = RAttachment.as("b")
    val a = RAttachmentArchive.as("a")
    val i = RItem.as("i")

    Select(
      select(a.all),
      from(a)
        .innerJoin(b, b.id === a.id)
        .innerJoin(i, i.id === b.itemId),
      a.id === attachId && b.id === attachId && i.cid === collective
    ).build.query[RAttachmentArchive].option
  }

  def findByMessageIdAndCollective(
      messageIds: NonEmptyList[String],
      collective: Ident
  ): ConnectionIO[Vector[RAttachmentArchive]] = {
//    val bId    = RAttachment.Columns.id.prefix("b")
//    val bItem  = RAttachment.Columns.itemId.prefix("b")
//    val aMsgId = Columns.messageId.prefix("a")
//    val aId    = Columns.id.prefix("a")
//    val iId    = RItem.Columns.id.prefix("i")
//    val iColl  = RItem.Columns.cid.prefix("i")
//
//    val from = table ++ fr"a INNER JOIN" ++
//      RAttachment.table ++ fr"b ON" ++ aId.is(bId) ++
//      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ bItem.is(iId)
//
//    val where = and(aMsgId.isIn(messageIds), iColl.is(collective))
//
//    selectSimple(all.map(_.prefix("a")), from, where).query[RAttachmentArchive].to[Vector]
    val b = RAttachment.as("b")
    val a = RAttachmentArchive.as("a")
    val i = RItem.as("i")
    Select(
      select(a.all),
      from(a)
        .innerJoin(b, b.id === a.id)
        .innerJoin(i, i.id === b.itemId),
      a.messageId.in(messageIds) && i.cid === collective
    ).build.query[RAttachmentArchive].to[Vector]
  }

  def findByItemWithMeta(
      id: Ident
  ): ConnectionIO[Vector[(RAttachmentArchive, FileMeta)]] = {
    import bitpeace.sql._

//    val aId       = Columns.id.prefix("a")
//    val afileMeta = fileId.prefix("a")
//    val bPos      = RAttachment.Columns.position.prefix("b")
//    val bId       = RAttachment.Columns.id.prefix("b")
//    val bItem     = RAttachment.Columns.itemId.prefix("b")
//    val mId       = RFileMeta.as("m").id.column
//
//    val cols = all.map(_.prefix("a")) ++ RFileMeta.as("m").all.map(_.column).toList
//    val from = table ++ fr"a INNER JOIN" ++
//      Fragment.const(RFileMeta.T.tableName) ++ fr"m ON" ++ afileMeta.is(
//        mId
//      ) ++ fr"INNER JOIN" ++
//      RAttachment.table ++ fr"b ON" ++ aId.is(bId)
//    val where = bItem.is(id)
//
//    (selectSimple(cols, from, where) ++ orderBy(bPos.asc))
//      .query[(RAttachmentArchive, FileMeta)]
//      .to[Vector]
    val a = RAttachmentArchive.as("a")
    val b = RAttachment.as("b")
    val m = RFileMeta.as("m")
    Select(
      select(a.all, m.all),
      from(a)
        .innerJoin(m, a.fileId === m.id)
        .innerJoin(b, a.id === b.id),
      b.itemId === id
    ).orderBy(b.position.asc).build.query[(RAttachmentArchive, FileMeta)].to[Vector]
  }

  /** If the given attachment id has an associated archive, this returns
    * the number of all associated attachments. Returns 0 if there is
    * no archive for the given attachment.
    */
  def countEntries(attachId: Ident): ConnectionIO[Int] =
//    val qFileId = selectSimple(Seq(fileId), table, id.is(attachId))
//    val q       = selectCount(id, table, fileId.isSubquery(qFileId))
//    q.query[Int].unique
    Select(
      count(T.id).s,
      from(T),
      T.fileId.in(Select(T.fileId.s, from(T), T.id === attachId))
    ).build.query[Int].unique
  //TODO this looks strange, can be simplified

}
