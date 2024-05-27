/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.util

import cats.data.OptionT
import cats.effect._
import cats.syntax.all._
import cats.{Applicative, Monad}
import fs2.Stream
import fs2.io.file.{Files, Path, PosixPermissions}

import docspell.logging.Logger

/** Utility functions for directories. */
object Directory {

  def create[F[_]: Files: Applicative](dir: Path): F[Path] =
    Files[F]
      .createDirectories(dir, PosixPermissions.fromOctal("777"))
      .as(dir)

  def createAll[F[_]: Files: Applicative](dir: Path, dirs: Path*): F[Unit] =
    (dir :: dirs.toList).traverse_(Files[F].createDirectories(_))

  def nonEmpty[F[_]: Files: Sync](dir: Path): F[Boolean] =
    OptionT
      .whenM(Files[F].isDirectory(dir))(Files[F].list(dir).take(1).compile.toList)
      .map(_.nonEmpty)
      .isDefined

  def isEmpty[F[_]: Files: Sync](dir: Path): F[Boolean] =
    nonEmpty(dir).map(b => !b)

  def temp[F[_]: Files](parent: Path, prefix: String): Resource[F, Path] =
    for {
      _ <- Resource.eval(Files[F].createDirectories(parent))
      d <- mkTemp(parent, prefix)
    } yield d

  def createTemp[F[_]: Files: Monad](
      parent: Path,
      prefix: String
  ): F[Path] =
    for {
      _ <- Files[F].createDirectories(parent)
      d <- mkTemp_(parent, prefix)
    } yield d

  private def mkTemp[F[_]: Files](parent: Path, prefix: String): Resource[F, Path] =
    Files[F]
      .tempDirectory(
        parent.some,
        prefix,
        PosixPermissions.fromOctal("777")
      )

  private def mkTemp_[F[_]: Files](parent: Path, prefix: String): F[Path] =
    Files[F]
      .createTempDirectory(
        parent.some,
        prefix,
        PosixPermissions.fromOctal("777")
      )

  /** If `dir` contains only a single non-empty directory, then its contents are moved out
    * of it and the directory is deleted. This is applied repeatedly until the condition
    * doesn't apply anymore (there are multiple entries in the directory or none).
    */
  def unwrapSingle[F[_]: Sync: Files](logger: Logger[F], dir: Path): F[Boolean] =
    Stream
      .repeatEval(unwrapSingle1(logger, dir))
      .takeWhile(identity)
      .compile
      .fold(false)(_ || _)

  def unwrapSingle1[F[_]: Sync: Files](
      logger: Logger[F],
      dir: Path
  ): F[Boolean] =
    Files[F]
      .list(dir)
      .take(2)
      .compile
      .toList
      .flatMap {
        case subdir :: Nil =>
          nonEmpty(subdir)
            .flatMap {
              case false => false.pure[F]
              case true =>
                for {
                  _ <- Files[F]
                    .list(subdir)
                    .filter(p => p != dir)
                    .evalTap(c => logger.trace(s"Move $c -> ${dir / c.fileName}"))
                    .evalMap(child => Files[F].move(child, dir / child.fileName))
                    .compile
                    .drain
                  _ <- Files[F].delete(subdir)
                } yield true
            }

        case _ =>
          false.pure[F]
      }
}
