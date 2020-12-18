package docspell.store.records

import cats.data.NonEmptyList
import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RInvitation(id: Ident, created: Timestamp) {}

object RInvitation {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "invitation"

    val id      = Column[Ident]("id", this)
    val created = Column[Timestamp]("created", this)
    val all     = NonEmptyList.of[Column[_]](id, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def generate[F[_]: Sync]: F[RInvitation] =
    for {
      c <- Timestamp.current[F]
      i <- Ident.randomId[F]
    } yield RInvitation(i, c)

  def insert(v: RInvitation): ConnectionIO[Int] =
    DML.insert(T, T.all, fr"${v.id},${v.created}")

  def insertNew: ConnectionIO[RInvitation] =
    generate[ConnectionIO].flatMap(v => insert(v).map(_ => v))

  def findById(invite: Ident): ConnectionIO[Option[RInvitation]] =
    run(select(T.all), from(T), T.id === invite).query[RInvitation].option

  def delete(invite: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === invite)

  def useInvite(invite: Ident, minCreated: Timestamp): ConnectionIO[Boolean] = {
    val get = run(select(count(T.id)), from(T), T.id === invite && T.created > minCreated)
      .query[Int]
      .unique
    for {
      inv <- get
      _   <- delete(invite)
    } yield inv > 0
  }

  def deleteOlderThan(ts: Timestamp): ConnectionIO[Int] =
    DML.delete(T, T.created < ts)
}
