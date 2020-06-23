package docspell.store.records

import cats.implicits._
import cats.effect._
import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl._
import docspell.store.impl.Implicits._

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

  val table = fr"fts_migration"

  object Columns {
    val id          = Column("id")
    val version     = Column("version")
    val ftsEngine   = Column("fts_engine")
    val description = Column("description")
    val created     = Column("created")

    val all = List(id, version, ftsEngine, description, created)
  }
  import Columns._

  def insert(v: RFtsMigration): ConnectionIO[Int] =
    insertRow(
      table,
      all,
      fr"${v.id},${v.version},${v.ftsEngine},${v.description},${v.created}"
    ).updateWithLogHandler(LogHandler.nop).run

  def exists(vers: Int, engine: Ident): ConnectionIO[Boolean] =
    selectCount(id, table, and(version.is(vers), ftsEngine.is(engine)))
      .query[Int]
      .unique
      .map(_ > 0)

  def deleteById(rId: Ident): ConnectionIO[Int] =
    deleteFrom(table, id.is(rId)).update.run
}
