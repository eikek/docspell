package docspell.store.records

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

final case class RFtsMigration(
    id: Ident,
    version: Int,
    ftsEngine: Ident,
    description: String,
    created: Timestamp
)

object RFtsMigration {

  def create[F[_]: Sync](
      version: Int,
      ftsEngine: Ident,
      description: String
  ): F[RFtsMigration] =
    for {
      newId <- Ident.randomId[F]
      now   <- Timestamp.current[F]
    } yield RFtsMigration(newId, version, ftsEngine, description, now)

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "fts_migration"

    val id          = Column[Ident]("id", this)
    val version     = Column[Int]("version", this)
    val ftsEngine   = Column[Ident]("fts_engine", this)
    val description = Column[String]("description", this)
    val created     = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, version, ftsEngine, description, created)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RFtsMigration): ConnectionIO[Int] =
    DML
      .insertFragment(
        T,
        T.all,
        Seq(fr"${v.id},${v.version},${v.ftsEngine},${v.description},${v.created}")
      )
      .updateWithLogHandler(LogHandler.nop)
      .run

  def exists(vers: Int, engine: Ident): ConnectionIO[Boolean] =
    run(select(count(T.id)), from(T), T.version === vers && T.ftsEngine === engine)
      .query[Int]
      .unique
      .map(_ > 0)

  def deleteById(rId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === rId)
}
