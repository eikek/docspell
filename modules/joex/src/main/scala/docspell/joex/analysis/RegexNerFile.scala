/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.analysis

import cats.effect._
import cats.effect.std.Semaphore
import cats.implicits._
import fs2.io.file.{Files, Path}

import docspell.common._
import docspell.common.util.File
import docspell.store.Store
import docspell.store.queries.QCollective
import docspell.store.records.REquipment
import docspell.store.records.ROrganization
import docspell.store.records.RPerson

import io.circe.syntax._

/** Maintains a custom regex-ner file per collective for stanford's regexner annotator. */
trait RegexNerFile[F[_]] {

  def makeFile(collective: CollectiveId): F[Option[Path]]

}

object RegexNerFile {

  case class Config(maxEntries: Int, directory: Path, minTime: Duration)

  def apply[F[_]: Async: Files](
      cfg: Config,
      store: Store[F]
  ): Resource[F, RegexNerFile[F]] =
    for {
      dir <- File.withTempDir[F](cfg.directory, "regexner-")
      writer <- Resource.eval(Semaphore(1))
    } yield new Impl[F](cfg.copy(directory = dir), store, writer)

  final private class Impl[F[_]: Async: Files](
      cfg: Config,
      store: Store[F],
      writer: Semaphore[F] // TODO allow parallelism per collective
  ) extends RegexNerFile[F] {

    private[this] val logger = docspell.logging.getLogger[F]

    def makeFile(collective: CollectiveId): F[Option[Path]] =
      if (cfg.maxEntries > 0) doMakeFile(collective)
      else (None: Option[Path]).pure[F]

    def doMakeFile(collective: CollectiveId): F[Option[Path]] =
      for {
        now <- Timestamp.current[F]
        existing <- NerFile.find[F](collective, cfg.directory)
        result <- existing match {
          case Some(nf) =>
            val dur = Duration.between(nf.creation, now)
            if (dur > cfg.minTime)
              logger.debug(
                s"Cache time elapsed ($dur > ${cfg.minTime}). Check for new state."
              ) *> updateFile(
                collective,
                now,
                Some(nf)
              )
            else nf.nerFilePath(cfg.directory).some.pure[F]
          case None =>
            updateFile(collective, now, None)
        }
      } yield result

    private def updateFile(
        collective: CollectiveId,
        now: Timestamp,
        current: Option[NerFile]
    ): F[Option[Path]] =
      for {
        lastUpdate <- store.transact(Sql.latestUpdate(collective))
        result <- lastUpdate match {
          case None =>
            (None: Option[Path]).pure[F]
          case Some(lup) =>
            current match {
              case Some(cur) =>
                val nerf =
                  if (cur.updated == lup)
                    logger.debug(s"No state change detected.") *> updateTimestamp(
                      cur,
                      now
                    ) *> cur.pure[F]
                  else
                    logger.debug(
                      s"There have been state changes for collective '${collective.value}'. Reload NER file."
                    ) *> createFile(lup, collective, now)
                nerf.map(_.nerFilePath(cfg.directory).some)
              case None =>
                createFile(lup, collective, now)
                  .map(_.nerFilePath(cfg.directory).some)
            }
        }
      } yield result

    private def updateTimestamp(nf: NerFile, now: Timestamp): F[Unit] =
      writer.permit.use(_ =>
        for {
          file <- Sync[F].pure(nf.jsonFilePath(cfg.directory))
          _ <- file.parent match {
            case Some(p) => File.mkDir(p)
            case None    => ().pure[F]
          }
          _ <- File.writeString(file, nf.copy(creation = now).asJson.spaces2)
        } yield ()
      )

    private def createFile(
        lastUpdate: Timestamp,
        collective: CollectiveId,
        now: Timestamp
    ): F[NerFile] = {
      def update(nf: NerFile, text: String): F[Unit] =
        writer.permit.use(_ =>
          for {
            jsonFile <- Sync[F].pure(nf.jsonFilePath(cfg.directory))
            _ <- logger.debug(
              s"Writing custom NER file for collective '${collective.value}'"
            )
            _ <- jsonFile.parent match {
              case Some(p) => File.mkDir(p)
              case None    => ().pure[F]
            }
            _ <- File.writeString(nf.nerFilePath(cfg.directory), text)
            _ <- File.writeString(jsonFile, nf.asJson.spaces2)
          } yield ()
        )

      for {
        _ <- logger.info(
          s"Generating custom NER file for collective '${collective.value}'"
        )
        names <- store.transact(QCollective.allNames(collective, cfg.maxEntries))
        nerFile = NerFile(collective, lastUpdate, now)
        _ <- update(nerFile, NerFile.mkNerConfig(names))
      } yield nerFile
    }
  }

  object Sql {
    import doobie._
    import docspell.store.qb.DSL._
    import docspell.store.qb._

    def latestUpdate(collective: CollectiveId): ConnectionIO[Option[Timestamp]] = {
      def max_(col: Column[_], cidCol: Column[CollectiveId]): Select =
        Select(max(col).as("t"), from(col.table), cidCol === collective)

      val sql = union(
        max_(ROrganization.T.updated, ROrganization.T.cid),
        max_(RPerson.T.updated, RPerson.T.cid),
        max_(REquipment.T.updated, REquipment.T.cid)
      )
      val t = Column[Timestamp]("t", TableDef(""))

      run(select(max(t)), from(sql, "x"))
        .query[Option[Timestamp]]
        .option
        .map(_.flatten)
    }
  }
}
