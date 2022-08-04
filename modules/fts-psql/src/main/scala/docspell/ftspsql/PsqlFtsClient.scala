/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftspsql

import scala.concurrent.ExecutionContext

import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.ftsclient._
import docspell.logging.Logger

import com.zaxxer.hikari.HikariDataSource
import doobie._
import doobie.hikari.HikariTransactor
import doobie.implicits._

final class PsqlFtsClient[F[_]: Sync](cfg: PsqlConfig, xa: Transactor[F])
    extends FtsClient[F] {
  val engine = Ident.unsafe("postgres")

  val config = cfg
  private[ftspsql] val transactor = xa

  private[this] val searchSummary =
    FtsRepository.searchSummary(cfg.pgQueryParser, cfg.rankNormalization) _
  private[this] val search =
    FtsRepository.search(cfg.pgQueryParser, cfg.rankNormalization) _

  private[this] val replaceChunk =
    FtsRepository.replaceChunk(FtsRepository.getPgConfig(cfg.pgConfigSelect)) _
  private[this] val updateChunk =
    FtsRepository.updateChunk(FtsRepository.getPgConfig(cfg.pgConfigSelect)) _

  def initialize: F[List[FtsMigration[F]]] =
    Sync[F].pure(
      List(
        FtsMigration(
          0,
          engine,
          "initialize",
          DbMigration[F](cfg).run.as(FtsMigration.Result.WorkDone)
        ),
        FtsMigration(
          1,
          engine,
          "Re-Index if empty",
          FtsRepository.containsNoData
            .transact(xa)
            .map(empty =>
              if (empty) FtsMigration.Result.IndexAll else FtsMigration.Result.WorkDone
            )
        )
      )
    )

  def initializeNew: List[FtsMigration[F]] =
    List(
      FtsMigration(
        10,
        engine,
        "reset",
        FtsRepository.resetAll.transact(xa).as(FtsMigration.Result.workDone)
      ),
      FtsMigration(
        20,
        engine,
        "schema",
        DbMigration[F](cfg).run.as(FtsMigration.Result.workDone)
      ),
      FtsMigration(20, engine, "index all", FtsMigration.Result.indexAll.pure[F])
    )

  def search(q: FtsQuery): F[FtsResult] =
    for {
      startNanos <- Sync[F].delay(System.nanoTime())
      summary <- searchSummary(q).transact(xa)
      results <- search(q, true).transact(xa)
      endNanos <- Sync[F].delay(System.nanoTime())
      duration = Duration.nanos(endNanos - startNanos)
      res = SearchResult
        .toFtsResult(summary, results)
        .copy(qtime = duration)
    } yield res

  def indexData(logger: Logger[F], data: Stream[F, TextData]): F[Unit] =
    data
      .map(FtsRecord.fromTextData)
      .chunkN(50)
      .evalMap(chunk =>
        logger.debug(s"Add to fts index ${chunk.size} records") *>
          replaceChunk(chunk).transact(xa)
      )
      .compile
      .drain

  def updateIndex(logger: Logger[F], data: Stream[F, TextData]): F[Unit] =
    data
      .map(FtsRecord.fromTextData)
      .chunkN(50)
      .evalMap(chunk =>
        logger.debug(s"Update fts index with ${chunk.size} records") *>
          updateChunk(chunk).transact(xa)
      )
      .compile
      .drain

  def updateFolder(
      logger: Logger[F],
      itemId: Ident,
      collective: CollectiveId,
      folder: Option[Ident]
  ): F[Unit] =
    logger.debug(s"Update folder '${folder
        .map(_.id)}' in fts for collective ${collective.value} and item ${itemId.id}") *>
      FtsRepository.updateFolder(itemId, collective, folder).transact(xa).void

  def removeItem(logger: Logger[F], itemId: Ident): F[Unit] =
    logger.debug(s"Removing item from fts index: ${itemId.id}") *>
      FtsRepository.deleteByItemId(itemId).transact(xa).void

  def removeAttachment(logger: Logger[F], attachId: Ident): F[Unit] =
    logger.debug(s"Removing attachment from fts index: ${attachId.id}") *>
      FtsRepository.deleteByAttachId(attachId).transact(xa).void

  def clearAll(logger: Logger[F]): F[Unit] =
    logger.info(s"Deleting complete FTS index") *>
      FtsRepository.deleteAll.transact(xa).void

  def clear(logger: Logger[F], collective: CollectiveId): F[Unit] =
    logger.info(s"Deleting index for collective ${collective.value}") *>
      FtsRepository.delete(collective).transact(xa).void
}

object PsqlFtsClient {
  def apply[F[_]: Async](
      cfg: PsqlConfig,
      connectEC: ExecutionContext
  ): Resource[F, PsqlFtsClient[F]] = {
    val acquire = Sync[F].delay(new HikariDataSource())
    val free: HikariDataSource => F[Unit] = ds => Sync[F].delay(ds.close())

    for {
      ds <- Resource.make(acquire)(free)
      _ = Resource.pure {
        ds.setJdbcUrl(cfg.url.asString)
        ds.setUsername(cfg.user)
        ds.setPassword(cfg.password.pass)
        ds.setDriverClassName("org.postgresql.Driver")
      }
      xa = HikariTransactor[F](ds, connectEC)

      pc = new PsqlFtsClient[F](cfg, xa)
    } yield pc
  }

  def fromTransactor[F[_]: Async](cfg: PsqlConfig, xa: Transactor[F]): PsqlFtsClient[F] =
    new PsqlFtsClient[F](cfg, xa)
}
