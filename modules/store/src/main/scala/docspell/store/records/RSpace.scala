package docspell.store.records

import cats.effect._
import cats.implicits._
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

  def newSpace[F[_]: Sync](name: String, account: AccountId): F[RSpace] =
    for {
      nId <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RSpace(nId, name, account.collective, account.user, now)

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

  def update(v: RSpace): ConnectionIO[Int] =
    updateRow(
      table,
      and(id.is(v.id), collective.is(v.collectiveId), owner.is(v.owner)),
      name.setTo(v.name)
    ).update.run

  def existsByName(coll: Ident, spaceName: String): ConnectionIO[Boolean] =
    selectCount(id, table, and(collective.is(coll), name.is(spaceName)))
      .query[Int]
      .unique
      .map(_ > 0)

  def findById(spaceId: Ident): ConnectionIO[Option[RSpace]] = {
    val sql = selectSimple(all, table, id.is(spaceId))
    sql.query[RSpace].option
  }

  def findAll(
      coll: Ident,
      nameQ: Option[String],
      order: Columns.type => Column
  ): ConnectionIO[Vector[RSpace]] = {
    val q = Seq(collective.is(coll)) ++ (nameQ match {
      case Some(str) => Seq(name.lowerLike(s"%${str.toLowerCase}%"))
      case None      => Seq.empty
    })
    val sql = selectSimple(all, table, and(q)) ++ orderBy(order(Columns).f)
    sql.query[RSpace].to[Vector]
  }

}
