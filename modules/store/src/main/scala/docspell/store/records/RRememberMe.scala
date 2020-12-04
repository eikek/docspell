package docspell.store.records

import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.impl._

import doobie._
import doobie.implicits._

case class RRememberMe(id: Ident, accountId: AccountId, created: Timestamp, uses: Int) {}

object RRememberMe {

  val table = fr"rememberme"

  object Columns {
    val id       = Column("id")
    val cid      = Column("cid")
    val username = Column("login")
    val created  = Column("created")
    val uses     = Column("uses")
    val all      = List(id, cid, username, created, uses)
  }
  import Columns._

  def generate[F[_]: Sync](account: AccountId): F[RRememberMe] =
    for {
      c <- Timestamp.current[F]
      i <- Ident.randomId[F]
    } yield RRememberMe(i, account, c, 0)

  def insert(v: RRememberMe): ConnectionIO[Int] =
    insertRow(
      table,
      all,
      fr"${v.id},${v.accountId.collective},${v.accountId.user},${v.created},${v.uses}"
    ).update.run

  def insertNew(acc: AccountId): ConnectionIO[RRememberMe] =
    generate[ConnectionIO](acc).flatMap(v => insert(v).map(_ => v))

  def findById(rid: Ident): ConnectionIO[Option[RRememberMe]] =
    selectSimple(all, table, id.is(rid)).query[RRememberMe].option

  def delete(rid: Ident): ConnectionIO[Int] =
    deleteFrom(table, id.is(rid)).update.run

  def incrementUse(rid: Ident): ConnectionIO[Int] =
    updateRow(table, id.is(rid), uses.increment(1)).update.run

  def useRememberMe(
      rid: Ident,
      minCreated: Timestamp
  ): ConnectionIO[Option[RRememberMe]] = {
    val get = selectSimple(all, table, and(id.is(rid), created.isGt(minCreated)))
      .query[RRememberMe]
      .option
    for {
      inv <- get
      _   <- incrementUse(rid)
    } yield inv
  }

  def deleteOlderThan(ts: Timestamp): ConnectionIO[Int] =
    deleteFrom(table, created.isLt(ts)).update.run
}
