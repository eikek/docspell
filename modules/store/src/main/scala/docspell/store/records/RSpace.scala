package docspell.store.records

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RSpace(
    id: Ident,
    name: String,
    collectiveId: Ident,
    owner: Ident,
    created: Timestamp
)

object RSpace {

  val table = fr"space"

  object Columns {

    val id         = Column("id")
    val name       = Column("name")
    val collective = Column("cid")
    val owner      = Column("owner")
    val created    = Column("created")

    val all = List(id, name, collective, owner, created)
  }

  import Columns._

  def insert(value: RSpace): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      all,
      fr"${value.id},${value.name},${value.collectiveId},${value.owner},${value.created}"
    )
    sql.update.run
  }

}
