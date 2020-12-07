package docspell.store.qb.model

import docspell.store.qb._
import docspell.common._
import doobie.implicits._
import docspell.store.impl.DoobieMeta._
import doobie._

case class PersonRecord(id: Long, name: String, created: Timestamp)

object PersonRecord {

  final case class Table(alias: Option[String]) extends TableDef {

    val tableName = "person"

    val id      = Column[Long]("id", this)
    val name    = Column[String]("name", this)
    val created = Column[Timestamp]("created", this)

    val all = List(id, name, created)
  }

  def as(alias: String): Table =
    Table(Some(alias))

  def table: Table = Table(None)

  def update(set: UpdateTable.Setter[_], sets: UpdateTable.Setter[_]*): UpdateTable =
    UpdateTable(table, None, sets :+ set)

  def insertAll(v: PersonRecord): ConnectionIO[Int] =
    InsertTable(
      table,
      table.all,
      fr"${v.id},${v.name},${v.created}"
    ).toFragment.update.run
}
