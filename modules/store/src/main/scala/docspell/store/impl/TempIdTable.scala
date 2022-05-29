package docspell.store.impl

import cats.Foldable
import cats.data.NonEmptyList
import cats.effect._
import cats.syntax.all._
import docspell.common.Ident
import docspell.store.Db
import docspell.store.qb.{Column, TableDef}
import docspell.store.impl.DoobieMeta._
import doobie._
import doobie.implicits._

/** Temporary table used to store item ids fetched from fulltext search */
object TempIdTable {
  case class Row(id: Ident)
  case class Table(tableName: String, alias: Option[String], dbms: Db) extends TableDef {
    val id: Column[Ident] = Column("id", this)

    val all: NonEmptyList[Column[_]] = NonEmptyList.of(id)

    def as(newAlias: String): Table = copy(alias = Some(newAlias))

    def insertAll[F[_]: Foldable](rows: F[Row]): ConnectionIO[Int] =
      insertBatch(this, rows)

    def dropTable: ConnectionIO[Int] =
      TempIdTable.dropTable(Fragment.const0(tableName)).update.run

    def createIndex: ConnectionIO[Unit] = {
      val analyze = dbms.fold(
        TempIdTable.analyzeTablePg(this),
        Sync[ConnectionIO].unit,
        Sync[ConnectionIO].unit
      )

      TempIdTable.createIndex(this) *> analyze
    }
  }

  def createTable(db: Db, name: String): ConnectionIO[Table] = {
    val stmt = db.fold(
      createTablePostgreSQL(Fragment.const(name)),
      createTableMariaDB(Fragment.const0(name)),
      createTableH2(Fragment.const0(name))
    )
    stmt.as(Table(name, None, db))
  }

  private def dropTable(name: Fragment): Fragment =
    sql"""DROP TABLE IF EXISTS $name"""

  private def createTableH2(name: Fragment): ConnectionIO[Int] =
    sql"""${dropTable(name)}; CREATE LOCAL TEMPORARY TABLE $name (
         |  id varchar not null
         |);""".stripMargin.update.run

  private def createTableMariaDB(name: Fragment): ConnectionIO[Int] =
    dropTable(name).update.run *>
      sql"CREATE TEMPORARY TABLE $name (id varchar(254) not null);".update.run

  private def createTablePostgreSQL(name: Fragment): ConnectionIO[Int] =
    sql"""CREATE TEMPORARY TABLE IF NOT EXISTS $name (
         |  id varchar not null
         |) ON COMMIT DROP;""".stripMargin.update.run

  private def createIndex(table: Table): ConnectionIO[Unit] = {
    val idxName = Fragment.const0(s"${table.tableName}_id_idx")
    val tableName = Fragment.const0(table.tableName)
    val col = Fragment.const0(table.id.name)
    sql"""CREATE INDEX IF NOT EXISTS $idxName ON $tableName($col);""".update.run.void
  }

  private def analyzeTablePg(table: Table): ConnectionIO[Unit] = {
    val tableName = Fragment.const0(table.tableName)
    sql"ANALYZE $tableName".update.run.void
  }

  private def insertBatch[F[_]: Foldable](table: Table, rows: F[Row]) = {
    val sql =
      s"INSERT INTO ${table.tableName} (${table.id.name}) VALUES (?)"

    Update[Row](sql).updateMany(rows)
  }
}
