package docspell.store.records

import bitpeace.FileMeta
import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl._
import docspell.store.impl.Implicits._

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

  val table = fr"attachment_archive"

  object Columns {
    val id        = Column("id")
    val fileId    = Column("file_id")
    val name      = Column("filename")
    val messageId = Column("message_id")
    val created   = Column("created")

    val all = List(id, fileId, name, messageId, created)
  }

  import Columns._

  def of(ra: RAttachment, mId: Option[String]): RAttachmentArchive =
    RAttachmentArchive(ra.id, ra.fileId, ra.name, mId, ra.created)

  def insert(v: RAttachmentArchive): ConnectionIO[Int] =
    insertRow(table, all, fr"${v.id},${v.fileId},${v.name},${v.messageId},${v.created}").update.run

  def findById(attachId: Ident): ConnectionIO[Option[RAttachmentArchive]] =
    selectSimple(all, table, id.is(attachId)).query[RAttachmentArchive].option

  def delete(attachId: Ident): ConnectionIO[Int] =
    deleteFrom(table, id.is(attachId)).update.run

  def deleteAll(fId: Ident): ConnectionIO[Int] =
    deleteFrom(table, fileId.is(fId)).update.run

  def findByIdAndCollective(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachmentArchive]] = {
    val bId   = RAttachment.Columns.id.prefix("b")
    val aId   = Columns.id.prefix("a")
    val bItem = RAttachment.Columns.itemId.prefix("b")
    val iId   = RItem.Columns.id.prefix("i")
    val iColl = RItem.Columns.cid.prefix("i")

    val from = table ++ fr"a INNER JOIN" ++
      RAttachment.table ++ fr"b ON" ++ aId.is(bId) ++
      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ bItem.is(iId)

    val where = and(aId.is(attachId), bId.is(attachId), iColl.is(collective))

    selectSimple(all.map(_.prefix("a")), from, where).query[RAttachmentArchive].option
  }

  def findByItemWithMeta(
      id: Ident
  ): ConnectionIO[Vector[(RAttachmentArchive, FileMeta)]] = {
    import bitpeace.sql._

    val aId       = Columns.id.prefix("a")
    val afileMeta = fileId.prefix("a")
    val bPos      = RAttachment.Columns.position.prefix("b")
    val bId       = RAttachment.Columns.id.prefix("b")
    val bItem     = RAttachment.Columns.itemId.prefix("b")
    val mId       = RFileMeta.Columns.id.prefix("m")

    val cols = all.map(_.prefix("a")) ++ RFileMeta.Columns.all.map(_.prefix("m"))
    val from = table ++ fr"a INNER JOIN" ++
      RFileMeta.table ++ fr"m ON" ++ afileMeta.is(mId) ++ fr"INNER JOIN" ++
      RAttachment.table ++ fr"b ON" ++ aId.is(bId)
    val where = bItem.is(id)

    (selectSimple(cols, from, where) ++ orderBy(bPos.asc))
      .query[(RAttachmentArchive, FileMeta)]
      .to[Vector]
  }

  /** If the given attachment id has an associated archive, this returns
    * the number of all associated attachments. Returns 0 if there is
    * no archive for the given attachment.
    */
  def countEntries(attachId: Ident): ConnectionIO[Int] = {
    val qFileId = selectSimple(Seq(fileId), table, id.is(attachId))
    val q       = selectCount(id, table, fileId.isSubquery(qFileId))
    q.query[Int].unique
  }
}
