/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.fts

import cats.Foldable
import cats.data.NonEmptyList
import cats.effect.Sync
import cats.syntax.all._
import fs2.Pipe

import docspell.common._
import docspell.ftsclient.FtsResult
import docspell.store.Db
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

/** Temporary table used to store item ids fetched from fulltext search */
case class RFtsResult(id: Ident, score: Option[Double], context: Option[ContextEntry])

object RFtsResult {
  def fromResult(result: FtsResult)(m: FtsResult.ItemMatch): RFtsResult = {
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
    RFtsResult(m.itemId, m.score.some, context)
  }

  def prepareTable(db: Db, name: String): Pipe[ConnectionIO, FtsResult, Table] =
    TempFtsOps.prepareTable(db, name)

  case class Table(tableName: String, alias: Option[String], dbms: Db) extends TableDef {
    val id: Column[Ident] = Column("id", this)
    val score: Column[Double] = Column("score", this)
    val context: Column[ContextEntry] = Column("context", this)

    val all: NonEmptyList[Column[_]] = NonEmptyList.of(id, score, context)

    def as(newAlias: String): Table = copy(alias = Some(newAlias))

    def distinctCte(name: String) =
      dbms.fold(
        TempFtsOps.distinctCtePg(this, name),
        TempFtsOps.distinctCteMaria(this, name),
        TempFtsOps.distinctCteH2(this, name)
      )

    def distinctCteSimple(name: String) =
      CteBind(copy(tableName = name) -> Select(select(id), from(this)).distinct)

    def insertAll[F[_]: Foldable](rows: F[RFtsResult]): ConnectionIO[Int] =
      TempFtsOps.insertBatch(this, rows)

    def dropTable: ConnectionIO[Int] =
      TempFtsOps.dropTable(Fragment.const0(tableName)).update.run

    def createIndex: ConnectionIO[Unit] = {
      val analyze = dbms.fold(
        TempFtsOps.analyzeTablePg(this),
        cio.unit,
        cio.unit
      )

      TempFtsOps.createIndex(this) *> analyze
    }

    def insert: Pipe[ConnectionIO, FtsResult, Int] =
      in => in.evalMap(res => insertAll(res.results.map(RFtsResult.fromResult(res))))
  }

  private val cio: Sync[ConnectionIO] = Sync[ConnectionIO]
}
