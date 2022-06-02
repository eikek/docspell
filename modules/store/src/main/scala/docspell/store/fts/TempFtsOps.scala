/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.fts

import cats.syntax.all._
import cats.{Foldable, Monad}
import fs2.{Pipe, Stream}

import docspell.common.Duration
import docspell.ftsclient.FtsResult
import docspell.store.Db
import docspell.store.fts.RFtsResult.Table
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

private[fts] object TempFtsOps {
  private[this] val logger = docspell.logging.getLogger[ConnectionIO]

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
        _ <- if (n > 500) Stream.eval(tt.createIndex) else Stream(())
        duration <- Stream.eval(timed)
        _ <- Stream.eval(
          logger.debug(
            s"Creating temporary fts table ($n elements) took: ${duration.formatExact}"
          )
        )
      } yield tt

  def dropTable(name: Fragment): Fragment =
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

  def createIndex(table: Table): ConnectionIO[Unit] = {
    val tableName = Fragment.const0(table.tableName)

    val idIdxName = Fragment.const0(s"${table.tableName}_id_idx")
    val id = Fragment.const0(table.id.name)
    val scoreIdxName = Fragment.const0(s"${table.tableName}_score_idx")
    val score = Fragment.const0(table.score.name)

    sql"CREATE INDEX IF NOT EXISTS $idIdxName ON $tableName($id)".update.run.void *>
      sql"CREATE INDEX IF NOT EXISTS $scoreIdxName ON $tableName($score)".update.run.void
  }

  def analyzeTablePg(table: Table): ConnectionIO[Unit] = {
    val tableName = Fragment.const0(table.tableName)
    sql"ANALYZE $tableName".update.run.void
  }

//  // slowest (9 runs, 6000 rows each, ~170ms)
//  def insertBatch2[F[_]: Foldable](table: Table, rows: F[RFtsResult]) = {
//    val sql =
//      s"""INSERT INTO ${table.tableName}
//         |  (${table.id.name}, ${table.score.name}, ${table.context.name})
//         |  VALUES (?, ?, ?)""".stripMargin
//
//    Update[RFtsResult](sql).updateMany(rows)
//  }

//  // better (~115ms)
//  def insertBatch3[F[_]: Foldable](
//                                    table: Table,
//                                    rows: F[RFtsResult]
//                                  ): ConnectionIO[Int] = {
//    val values = rows
//      .foldl(List.empty[Fragment]) { (res, row) =>
//        sql"(${row.id},${row.score},${row.context})" :: res
//      }
//
//    DML.insertMulti(table, table.all, values)
//  }

  // ~96ms
  def insertBatch[F[_]: Foldable](
      table: Table,
      rows: F[RFtsResult]
  ): ConnectionIO[Int] = {
    val values = rows
      .foldl(List.empty[String]) { (res, _) =>
        "(?,?,?)" :: res
      }
      .mkString(",")
    if (values.isEmpty) Monad[ConnectionIO].pure(0)
    else {
      val sql =
        s"""INSERT INTO ${table.tableName}
           |  (${table.id.name}, ${table.score.name}, ${table.context.name})
           |  VALUES $values""".stripMargin

      val encoder = io.circe.Encoder[ContextEntry]
      doobie.free.FC.raw { conn =>
        val pst = conn.prepareStatement(sql)
        rows.foldl(0) { (index, row) =>
          pst.setString(index + 1, row.id.id)
          row.score
            .fold(pst.setNull(index + 2, java.sql.Types.DOUBLE))(d =>
              pst.setDouble(index + 2, d)
            )
          row.context
            .fold(pst.setNull(index + 3, java.sql.Types.VARCHAR))(c =>
              pst.setString(index + 3, encoder(c).noSpaces)
            )
          index + 3
        }
        pst.executeUpdate()
      }
    }
  }

  def distinctCtePg(table: Table, name: String): CteBind =
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

  def distinctCteMaria(table: Table, name: String): CteBind =
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

  def distinctCteH2(table: Table, name: String): CteBind =
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
}
