package docspell.store.qb.model

import cats.data.NonEmptyList

import docspell.store.qb._

case class CourseRecord(
    id: Long,
    name: String,
    ownerId: Long,
    lecturerId: Option[Long],
    lessons: Int
)

object CourseRecord {

  final case class Table(alias: Option[String]) extends TableDef {

    override val tableName = "course"

    val id         = Column[Long]("id", this)
    val name       = Column[String]("name", this)
    val ownerId    = Column[Long]("owner_id", this)
    val lecturerId = Column[Long]("lecturer_id", this)
    val lessons    = Column[Int]("lessons", this)

    val all = NonEmptyList.of[Column[_]](id, name, ownerId, lecturerId, lessons)
  }

  def as(alias: String): Table =
    Table(Some(alias))

}
