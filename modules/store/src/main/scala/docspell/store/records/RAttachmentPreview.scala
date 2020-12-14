package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import bitpeace.FileMeta
import doobie._
import doobie.implicits._

/** A preview image of an attachment. The `id` is shared with the
  * attachment, to create a 1-1 (or 0..1-1) relationship.
  */
case class RAttachmentPreview(
    id: Ident, //same as RAttachment.id
    fileId: Ident,
    name: Option[String],
    created: Timestamp
)

object RAttachmentPreview {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "attachment_preview"

    val id      = Column[Ident]("id", this)
    val fileId  = Column[Ident]("file_id", this)
    val name    = Column[String]("filename", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, fileId, name, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  val table = fr"attachment_preview"
  object Columns {
    import docspell.store.impl._
    val id      = Column("id")
    val fileId  = Column("file_id")
    val name    = Column("filename")
    val created = Column("created")

    val all = List(id, fileId, name, created)
  }

  def insert(v: RAttachmentPreview): ConnectionIO[Int] =
    DML.insert(T, T.all, fr"${v.id},${v.fileId},${v.name},${v.created}")

  def findById(attachId: Ident): ConnectionIO[Option[RAttachmentPreview]] =
    run(select(T.all), from(T), T.id === attachId).query[RAttachmentPreview].option

  def delete(attachId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === attachId)

  def findByIdAndCollective(
      attachId: Ident,
      collective: Ident
  ): ConnectionIO[Option[RAttachmentPreview]] = {
    val b = RAttachment.as("b")
    val a = RAttachmentPreview.as("a")
    val i = RItem.as("i")

    Select(
      select(a.all),
      from(a)
        .innerJoin(b, a.id === b.id)
        .innerJoin(i, i.id === b.itemId),
      a.id === attachId && b.id === attachId && i.cid === collective
    ).build.query[RAttachmentPreview].option
  }

  def findByItem(itemId: Ident): ConnectionIO[Vector[RAttachmentPreview]] = {
    val s = RAttachmentPreview.as("s")
    val a = RAttachment.as("a")
    Select(
      select(s.all),
      from(s)
        .innerJoin(a, s.id === a.id),
      a.itemId === itemId
    ).build.query[RAttachmentPreview].to[Vector]
  }

  def findByItemAndCollective(
      itemId: Ident,
      coll: Ident
  ): ConnectionIO[Option[RAttachmentPreview]] = {
    val s = RAttachmentPreview.as("s")
    val a = RAttachment.as("a")
    val i = RItem.as("i")

    Select(
      select(s.all).append(a.position.s),
      from(s)
        .innerJoin(a, s.id === a.id)
        .innerJoin(i, i.id === a.itemId),
      a.itemId === itemId && i.cid === coll
    ).build
      .query[(RAttachmentPreview, Int)]
      .to[Vector]
      .map(_.sortBy(_._2).headOption.map(_._1))
  }

  def findByItemWithMeta(
      id: Ident
  ): ConnectionIO[Vector[(RAttachmentPreview, FileMeta)]] = {
    import bitpeace.sql._

    val a = RAttachmentPreview.as("a")
    val b = RAttachment.as("b")
    val m = RFileMeta.as("m")

    Select(
      select(a.all, m.all),
      from(a)
        .innerJoin(m, a.fileId === m.id)
        .innerJoin(b, b.id === a.id),
      b.itemId === id
    ).orderBy(b.position.asc).build.query[(RAttachmentPreview, FileMeta)].to[Vector]
  }
}
