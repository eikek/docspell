/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.effect._
import cats.syntax.all._
import cats.{Applicative, Monad}
import fs2.io.file.{Files, Path, PosixPermissions}

object Directory {

  def create[F[_]: Files: Applicative](dir: Path): F[Path] =
    Files[F]
      .createDirectories(dir, PosixPermissions.fromOctal("777"))
      .as(dir)

  def createAll[F[_]: Files: Applicative](dir: Path, dirs: Path*): F[Unit] =
    (dir :: dirs.toList).traverse_(Files[F].createDirectories(_))

  def nonEmpty[F[_]: Files: Sync](dir: Path): F[Boolean] =
    List(
      Files[F].isDirectory(dir),
      Files[F].list(dir).take(1).compile.last.map(_.isDefined)
    ).sequence.map(_.forall(identity))

  def isEmpty[F[_]: Files: Sync](dir: Path): F[Boolean] =
    nonEmpty(dir).map(b => !b)

  def temp[F[_]: Files](parent: Path, prefix: String): Resource[F, Path] =
    for {
      _ <- Resource.eval(Files[F].createDirectories(parent))
      d <- mkTemp(parent, prefix)
    } yield d

  def temp2[F[_]: Files](
      parent: Path,
      prefix1: String,
      prefix2: String
  ): Resource[F, (Path, Path)] =
    for {
      _ <- Resource.eval(Files[F].createDirectories(parent))
      a <- mkTemp(parent, prefix1)
      b <- mkTemp(parent, prefix2)
    } yield (a, b)

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
}
