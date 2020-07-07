package docspell.store.records

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RSpaceMember(
    id: Ident,
    spaceId: Ident,
    userId: Ident,
    created: Timestamp
)

object RSpaceMember {

  def newMember[F[_]: Sync](space: Ident, user: Ident): F[RSpaceMember] =
    for {
      nId <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RSpaceMember(nId, space, user, now)

  val table = fr"space_member"

  object Columns {

    val id      = Column("id")
    val space   = Column("space_id")
    val user    = Column("user_id")
    val created = Column("created")

    val all = List(id, space, user, created)
  }

  import Columns._

  def insert(value: RSpaceMember): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      all,
      fr"${value.id},${value.spaceId},${value.userId},${value.created}"
    )
    sql.update.run
  }

  def findByUserId(userId: Ident, spaceId: Ident): ConnectionIO[Option[RSpaceMember]] =
    selectSimple(all, table, and(space.is(spaceId), user.is(userId)))
      .query[RSpaceMember]
      .option

  def delete(userId: Ident, spaceId: Ident): ConnectionIO[Int] =
    deleteFrom(table, and(space.is(spaceId), user.is(userId))).update.run

  def deleteAll(spaceId: Ident): ConnectionIO[Int] =
    deleteFrom(table, space.is(spaceId)).update.run
}
