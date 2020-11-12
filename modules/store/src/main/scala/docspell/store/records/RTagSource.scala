package docspell.store.records

import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.impl._

import doobie._
import doobie.implicits._

case class RTagSource(id: Ident, sourceId: Ident, tagId: Ident) {}

object RTagSource {

  val table = fr"tagsource"

  object Columns {
    val id       = Column("id")
    val sourceId = Column("source_id")
    val tagId    = Column("tag_id")
    val all      = List(id, sourceId, tagId)
  }
  import Columns._

  def createNew[F[_]: Sync](source: Ident, tag: Ident): F[RTagSource] =
    Ident.randomId[F].map(id => RTagSource(id, source, tag))

  def insert(v: RTagSource): ConnectionIO[Int] =
    insertRow(table, all, fr"${v.id},${v.sourceId},${v.tagId}").update.run

  def deleteSourceTags(source: Ident): ConnectionIO[Int] =
    deleteFrom(table, sourceId.is(source)).update.run

  def deleteTag(tid: Ident): ConnectionIO[Int] =
    deleteFrom(table, tagId.is(tid)).update.run

  def findBySource(source: Ident): ConnectionIO[Vector[RTagSource]] =
    selectSimple(all, table, sourceId.is(source)).query[RTagSource].to[Vector]

  def setAllTags(source: Ident, tags: Seq[Ident]): ConnectionIO[Int] =
    if (tags.isEmpty) 0.pure[ConnectionIO]
    else
      for {
        entities <- tags.toList.traverse(tagId =>
          Ident.randomId[ConnectionIO].map(id => RTagSource(id, source, tagId))
        )
        n <- insertRows(
          table,
          all,
          entities.map(v => fr"${v.id},${v.sourceId},${v.tagId}")
        ).update.run
      } yield n

}
