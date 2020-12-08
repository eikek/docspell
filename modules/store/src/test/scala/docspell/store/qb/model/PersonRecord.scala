package docspell.store.qb.model

import docspell.store.qb._
import docspell.common._

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

}
