package docspell.store.records

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.impl._

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

  val table = fr"attachment_source"

  object Columns {
    val id      = Column("id")
    val fileId  = Column("file_id")
    val name    = Column("filename")
    val created = Column("created")

    val all = List(id, fileId, name, created)
  }

  import Columns._

  def of(ra: RAttachment): RAttachmentSource =
    RAttachmentSource(ra.id, ra.fileId, ra.name, ra.created)

  def insert(v: RAttachmentSource): ConnectionIO[Int] =
    insertRow(table, all, fr"${v.id},${v.fileId},${v.name},${v.created}").update.run

  def findById(attachId: Ident): ConnectionIO[Option[RAttachmentSource]] =
    selectSimple(all, table, id.is(attachId)).query[RAttachmentSource].option

  def isSameFile(attachId: Ident, file: Ident): ConnectionIO[Boolean] =
    selectCount(id, table, and(id.is(attachId), fileId.is(file)))
      .query[Int]
      .unique
      .map(_ > 0)

  def isConverted(attachId: Ident): ConnectionIO[Boolean] = {
    val sId   = Columns.id.prefix("s")
    val sFile = Columns.fileId.prefix("s")
    val aId   = RAttachment.Columns.id.prefix("a")
    val aFile = RAttachment.Columns.fileId.prefix("a")

    val from = table ++ fr"s INNER JOIN" ++
      RAttachment.table ++ fr"a ON" ++ aId.is(sId)

    selectCount(aId, from, and(aId.is(attachId), aFile.isNot(sFile)))
      .query[Int]
      .unique
      .map(_ > 0)
  }

  def delete(attachId: Ident): ConnectionIO[Int] =
    deleteFrom(table, id.is(attachId)).update.run

  def findByIdAndCollective(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachmentSource]] = {
    val bId   = RAttachment.Columns.id.prefix("b")
    val aId   = Columns.id.prefix("a")
    val bItem = RAttachment.Columns.itemId.prefix("b")
    val iId   = RItem.Columns.id.prefix("i")
    val iColl = RItem.Columns.cid.prefix("i")

    val from = table ++ fr"a INNER JOIN" ++
      RAttachment.table ++ fr"b ON" ++ aId.is(bId) ++
      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ bItem.is(iId)

    val where = and(aId.is(attachId), bId.is(attachId), iColl.is(collective))

    selectSimple(all.map(_.prefix("a")), from, where).query[RAttachmentSource].option
  }

  def findByItem(itemId: Ident): ConnectionIO[Vector[RAttachmentSource]] = {
    val sId   = Columns.id.prefix("s")
    val aId   = RAttachment.Columns.id.prefix("a")
    val aItem = RAttachment.Columns.itemId.prefix("a")

    val from = table ++ fr"s INNER JOIN" ++ RAttachment.table ++ fr"a ON" ++ sId.is(aId)
    selectSimple(all.map(_.prefix("s")), from, aItem.is(itemId))
      .query[RAttachmentSource]
      .to[Vector]
  }

  def findByItemWithMeta(
      id: Ident
  ): ConnectionIO[Vector[(RAttachmentSource, FileMeta)]] = {
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
      .query[(RAttachmentSource, FileMeta)]
      .to[Vector]
  }

}
