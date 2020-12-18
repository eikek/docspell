package docspell.store.records

import cats.data.NonEmptyList
import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RTagSource(id: Ident, sourceId: Ident, tagId: Ident) {}

object RTagSource {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "tagsource"

    val id       = Column[Ident]("id", this)
    val sourceId = Column[Ident]("source_id", this)
    val tagId    = Column[Ident]("tag_id", this)
    val all      = NonEmptyList.of[Column[_]](id, sourceId, tagId)
  }

  private val t = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def createNew[F[_]: Sync](source: Ident, tag: Ident): F[RTagSource] =
    Ident.randomId[F].map(id => RTagSource(id, source, tag))

  def insert(v: RTagSource): ConnectionIO[Int] =
    DML.insert(t, t.all, fr"${v.id},${v.sourceId},${v.tagId}")

  def deleteSourceTags(source: Ident): ConnectionIO[Int] =
    DML.delete(t, t.sourceId === source)

  def deleteTag(tid: Ident): ConnectionIO[Int] =
    DML.delete(t, t.tagId === tid)

  def findBySource(source: Ident): ConnectionIO[Vector[RTagSource]] =
    run(select(t.all), from(t), t.sourceId === source).query[RTagSource].to[Vector]

  def setAllTags(source: Ident, tags: Seq[Ident]): ConnectionIO[Int] =
    if (tags.isEmpty) 0.pure[ConnectionIO]
    else
      for {
        entities <- tags.toList.traverse(tagId =>
          Ident.randomId[ConnectionIO].map(id => RTagSource(id, source, tagId))
        )
        n <- DML
          .insertMany(
            t,
            t.all,
            entities.map(v => fr"${v.id},${v.sourceId},${v.tagId}")
          )
      } yield n

}
