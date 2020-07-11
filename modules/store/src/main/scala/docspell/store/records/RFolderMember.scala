package docspell.store.records

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RFolderMember(
    id: Ident,
    folderId: Ident,
    userId: Ident,
    created: Timestamp
)

object RFolderMember {

  def newMember[F[_]: Sync](folder: Ident, user: Ident): F[RFolderMember] =
    for {
      nId <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RFolderMember(nId, folder, user, now)

  val table = fr"folder_member"

  object Columns {

    val id      = Column("id")
    val folder  = Column("folder_id")
    val user    = Column("user_id")
    val created = Column("created")

    val all = List(id, folder, user, created)
  }

  import Columns._

  def insert(value: RFolderMember): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      all,
      fr"${value.id},${value.folderId},${value.userId},${value.created}"
    )
    sql.update.run
  }

  def findByUserId(userId: Ident, folderId: Ident): ConnectionIO[Option[RFolderMember]] =
    selectSimple(all, table, and(folder.is(folderId), user.is(userId)))
      .query[RFolderMember]
      .option

  def delete(userId: Ident, folderId: Ident): ConnectionIO[Int] =
    deleteFrom(table, and(folder.is(folderId), user.is(userId))).update.run

  def deleteAll(folderId: Ident): ConnectionIO[Int] =
    deleteFrom(table, folder.is(folderId)).update.run
}
