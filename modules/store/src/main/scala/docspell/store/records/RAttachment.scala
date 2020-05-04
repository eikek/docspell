package docspell.store.records

import bitpeace.FileMeta
import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl._
import docspell.store.impl.Implicits._

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
      n2 <- deleteFrom(table, id.is(attachId)).update.run
    } yield n0 + n1 + n2

}
