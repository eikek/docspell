package docspell.store.records

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RSpaceItem(
    id: Ident,
    spaceId: Ident,
    itemId: Ident,
    created: Timestamp
)

object RSpaceItem {

  val table = fr"space"

  object Columns {

    val id      = Column("id")
    val space   = Column("space_id")
    val item    = Column("user_id")
    val created = Column("created")

    val all = List(id, space, user, created)
  }

  import Columns._

  def insert(value: RSpaceItem): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      all,
      fr"${value.id},${value.spaceId},${value.itemId},${value.created}"
    )
    sql.update.run
  }

}
