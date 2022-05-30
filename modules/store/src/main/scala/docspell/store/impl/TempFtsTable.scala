/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.impl

import cats.Foldable
import cats.data.NonEmptyList
import cats.effect._
import cats.syntax.all._
import fs2.{Pipe, Stream}

import docspell.common.{Duration, Ident}
import docspell.ftsclient.FtsResult
import docspell.store.Db
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

/** Temporary table used to store item ids fetched from fulltext search */
object TempFtsTable {
  private[this] val logger = docspell.logging.getLogger[ConnectionIO]

  case class Row(id: Ident, score: Option[Double], context: Option[ContextEntry])
  object Row {
    def from(result: FtsResult)(m: FtsResult.ItemMatch): Row = {
      val context = m.data match {
        case FtsResult.AttachmentData(_, attachName) =>
          result.highlight
            .get(m.id)
            .filter(_.nonEmpty)
            .map(str => ContextEntry(attachName, str))

        case FtsResult.ItemData =>
          result.highlight
            .get(m.id)
            .filter(_.nonEmpty)
            .map(str => ContextEntry("item", str))
      }
      Row(m.itemId, m.score.some, context)
    }
  }

  case class ContextEntry(name: String, context: List[String])
  object ContextEntry {
    implicit val jsonDecoder: Decoder[ContextEntry] = deriveDecoder
    implicit val jsonEncoder: Encoder[ContextEntry] = deriveEncoder

    implicit val meta: Meta[ContextEntry] =
      jsonMeta[ContextEntry]
  }

  case class Table(tableName: String, alias: Option[String], dbms: Db) extends TableDef {
    val id: Column[Ident] = Column("id", this)
    val score: Column[Double] = Column("score", this)
    val context: Column[ContextEntry] = Column("context", this)

    val all: NonEmptyList[Column[_]] = NonEmptyList.of(id, score, context)

    def as(newAlias: String): Table = copy(alias = Some(newAlias))

    def distinctCte(name: String) =
      dbms.fold(
        TempFtsTable.distinctCtePg(this, name),
        TempFtsTable.distinctCteMaria(this, name),
        TempFtsTable.distinctCteH2(this, name)
      )

    def distinctCteSimple(name: String) =
      CteBind(copy(tableName = name) -> Select(select(id), from(this)).distinct)

    def insertAll[F[_]: Foldable](rows: F[Row]): ConnectionIO[Int] =
      insertBatch(this, rows)

    def dropTable: ConnectionIO[Int] =
      TempFtsTable.dropTable(Fragment.const0(tableName)).update.run

    def createIndex: ConnectionIO[Unit] = {
      val analyze = dbms.fold(
        TempFtsTable.analyzeTablePg(this),
        cio.unit,
        cio.unit
      )

      TempFtsTable.createIndex(this) *> analyze
    }

    def insert: Pipe[ConnectionIO, FtsResult, Int] =
      in => in.evalMap(res => insertAll(res.results.map(Row.from(res))))
  }

  def createTable(db: Db, name: String): ConnectionIO[Table] = {
    val stmt = db.fold(
      createTablePostgreSQL(Fragment.const(name)),
      createTableMariaDB(Fragment.const0(name)),
      createTableH2(Fragment.const0(name))
    )
    stmt.as(Table(name, None, db))
  }

  def prepareTable(db: Db, name: String): Pipe[ConnectionIO, FtsResult, Table] =
    in =>
      for {
        timed <- Stream.eval(Duration.stopTime[ConnectionIO])
        tt <- Stream.eval(createTable(db, name))
        n <- in.through(tt.insert).foldMonoid
        _ <- Stream.eval(tt.createIndex)
        duration <- Stream.eval(timed)
        _ <- Stream.eval(
          logger.info(
            s"Creating temporary fts table ($n elements) took: ${duration.formatExact}"
          )
        )
      } yield tt

  private def dropTable(name: Fragment): Fragment =
    sql"""DROP TABLE IF EXISTS $name"""

  private def createTableH2(name: Fragment): ConnectionIO[Int] =
    sql"""${dropTable(name)}; CREATE LOCAL TEMPORARY TABLE $name (
         |  id varchar not null,
         |  score double precision,
         |  context text
         |);""".stripMargin.update.run

  private def createTableMariaDB(name: Fragment): ConnectionIO[Int] =
    dropTable(name).update.run *>
      sql"""CREATE TEMPORARY TABLE $name (
           |  id varchar(254) not null,
           |  score double,
           |  context mediumtext
           |)""".stripMargin.update.run

  private def createTablePostgreSQL(name: Fragment): ConnectionIO[Int] =
    sql"""CREATE TEMPORARY TABLE IF NOT EXISTS $name (
         |  id varchar not null,
         |  score double precision,
         |  context text
         |) ON COMMIT DROP;""".stripMargin.update.run

  private def createIndex(table: Table): ConnectionIO[Unit] = {
    val tableName = Fragment.const0(table.tableName)

    val idIdxName = Fragment.const0(s"${table.tableName}_id_idx")
    val id = Fragment.const0(table.id.name)
    val scoreIdxName = Fragment.const0(s"${table.tableName}_score_idx")
    val score = Fragment.const0(table.score.name)

    sql"CREATE INDEX IF NOT EXISTS $idIdxName ON $tableName($id)".update.run.void *>
      sql"CREATE INDEX IF NOT EXISTS $scoreIdxName ON $tableName($score)".update.run.void
  }

  private def analyzeTablePg(table: Table): ConnectionIO[Unit] = {
    val tableName = Fragment.const0(table.tableName)
    sql"ANALYZE $tableName".update.run.void
  }

  private def insertBatch[F[_]: Foldable](table: Table, rows: F[Row]) = {
    val sql =
      s"""INSERT INTO ${table.tableName}
         |  (${table.id.name}, ${table.score.name}, ${table.context.name})
         |  VALUES (?, ?, ?)""".stripMargin

    Update[Row](sql).updateMany(rows)
  }

  private def distinctCtePg(table: Table, name: String): CteBind =
    CteBind(
      table.copy(tableName = name) ->
        Select(
          select(
            table.id.s,
            max(table.score).as(table.score.name),
            rawFunction("string_agg", table.context.s, lit("','")).as(table.context.name)
          ),
          from(table)
        ).groupBy(table.id)
    )

  private def distinctCteMaria(table: Table, name: String): CteBind =
    CteBind(
      table.copy(tableName = name) ->
        Select(
          select(
            table.id.s,
            max(table.score).as(table.score.name),
            rawFunction("group_concat", table.context.s).as(table.context.name)
          ),
          from(table)
        ).groupBy(table.id)
    )

  private def distinctCteH2(table: Table, name: String): CteBind =
    CteBind(
      table.copy(tableName = name) ->
        Select(
          select(
            table.id.s,
            max(table.score).as(table.score.name),
            rawFunction("listagg", table.context.s, lit("','")).as(table.context.name)
          ),
          from(table)
        ).groupBy(table.id)
    )

  private val cio: Sync[ConnectionIO] = Sync[ConnectionIO]
}
