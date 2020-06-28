package docspell.store.records

import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.impl._

import doobie._
import doobie.implicits._

case class RInvitation(id: Ident, created: Timestamp) {}

object RInvitation {

  val table = fr"invitation"

  object Columns {
    val id      = Column("id")
    val created = Column("created")
    val all     = List(id, created)
  }
  import Columns._

  def generate[F[_]: Sync]: F[RInvitation] =
    for {
      c <- Timestamp.current[F]
      i <- Ident.randomId[F]
    } yield RInvitation(i, c)

  def insert(v: RInvitation): ConnectionIO[Int] =
    insertRow(table, all, fr"${v.id},${v.created}").update.run

  def insertNew: ConnectionIO[RInvitation] =
    generate[ConnectionIO].flatMap(v => insert(v).map(_ => v))

  def findById(invite: Ident): ConnectionIO[Option[RInvitation]] =
    selectSimple(all, table, id.is(invite)).query[RInvitation].option

  def delete(invite: Ident): ConnectionIO[Int] =
    deleteFrom(table, id.is(invite)).update.run

  def useInvite(invite: Ident, minCreated: Timestamp): ConnectionIO[Boolean] = {
    val get = selectCount(id, table, and(id.is(invite), created.isGt(minCreated)))
      .query[Int]
      .unique
    for {
      inv <- get
      _   <- delete(invite)
    } yield inv > 0
  }

  def deleteOlderThan(ts: Timestamp): ConnectionIO[Int] =
    deleteFrom(table, created.isLt(ts)).update.run
}
