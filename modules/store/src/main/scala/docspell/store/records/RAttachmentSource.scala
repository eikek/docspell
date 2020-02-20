package docspell.store.records

import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl._
import docspell.store.impl.Implicits._

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

  def delete(attachId: Ident): ConnectionIO[Int] =
    deleteFrom(table, id.is(attachId)).update.run

  def findByIdAndCollective(attachId: Ident, collective: Ident): ConnectionIO[Option[RAttachmentSource]] = {
    val bId = RAttachment.Columns.id.prefix("b")
    val aId = Columns.id.prefix("a")
    val bItem = RAttachment.Columns.itemId.prefix("b")
    val iId = RItem.Columns.id.prefix("i")
    val iColl = RItem.Columns.cid.prefix("i")

    val from = table ++ fr"a INNER JOIN" ++
      RAttachment.table ++ fr"b ON" ++ aId.is(bId) ++
      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ bItem.is(iId)

    val where = and(aId.is(attachId), bId.is(attachId), iColl.is(collective))

    selectSimple(all.map(_.prefix("a")), from, where).query[RAttachmentSource].option
  }
}
