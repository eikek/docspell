package docspell.store.records

import cats.effect._
import cats.implicits._
import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RFolder(
    id: Ident,
    name: String,
    collectiveId: Ident,
    owner: Ident,
    created: Timestamp
)

object RFolder {

  def newFolder[F[_]: Sync](name: String, account: AccountId): F[RFolder] =
    for {
      nId <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RFolder(nId, name, account.collective, account.user, now)

  val table = fr"folder"

  object Columns {

    val id         = Column("id")
    val name       = Column("name")
    val collective = Column("cid")
    val owner      = Column("owner")
    val created    = Column("created")

    val all = List(id, name, collective, owner, created)
  }

  import Columns._

  def insert(value: RFolder): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      all,
      fr"${value.id},${value.name},${value.collectiveId},${value.owner},${value.created}"
    )
    sql.update.run
  }

  def update(v: RFolder): ConnectionIO[Int] =
    updateRow(
      table,
      and(id.is(v.id), collective.is(v.collectiveId), owner.is(v.owner)),
      name.setTo(v.name)
    ).update.run

  def existsByName(coll: Ident, folderName: String): ConnectionIO[Boolean] =
    selectCount(id, table, and(collective.is(coll), name.is(folderName)))
      .query[Int]
      .unique
      .map(_ > 0)

  def findById(folderId: Ident): ConnectionIO[Option[RFolder]] = {
    val sql = selectSimple(all, table, id.is(folderId))
    sql.query[RFolder].option
  }

  def findAll(
      coll: Ident,
      nameQ: Option[String],
      order: Columns.type => Column
  ): ConnectionIO[Vector[RFolder]] = {
    val q = Seq(collective.is(coll)) ++ (nameQ match {
      case Some(str) => Seq(name.lowerLike(s"%${str.toLowerCase}%"))
      case None      => Seq.empty
    })
    val sql = selectSimple(all, table, and(q)) ++ orderBy(order(Columns).f)
    sql.query[RFolder].to[Vector]
  }

  def delete(folderId: Ident): ConnectionIO[Int] =
    deleteFrom(table, id.is(folderId)).update.run
}
