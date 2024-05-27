/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.effect._
import cats.syntax.all._
import fs2.Stream
import fs2.io.file.{Files, Path}

import docspell.common._
import docspell.common.syntax.file._
import docspell.common.util.{Directory, Zip}

final case class AddonArchive(url: LenientUri, name: String, version: String) {
  def nameAndVersion: String =
    s"$name-$version"

  def extractTo[F[_]: Async: Files](
      reader: UrlReader[F],
      directory: Path,
      withSubdir: Boolean = true,
      glob: Glob = Glob.all
  ): F[Path] = {
    val logger = docspell.logging.getLogger[F]
    val target =
      if (withSubdir) directory.absolute / nameAndVersion
      else directory.absolute

    Files[F]
      .exists(target)
      .flatMap {
        case true => target.pure[F]
        case false =>
          Files[F].createDirectories(target) *>
            reader(url)
              .through(Zip[F](logger.some).unzip(glob = glob, targetDir = target.some))
              .compile
              .drain
              .flatTap(_ => Directory.unwrapSingle[F](logger, target))
              .as(target)
      }
  }

  /** Read meta either from the given directory or extract the url to find the metadata
    * file to read
    */
  def readMeta[F[_]: Async: Files](
      urlReader: UrlReader[F],
      directory: Option[Path] = None
  ): F[AddonMeta] =
    directory
      .map(AddonMeta.findInDirectory[F])
      .getOrElse(AddonMeta.findInZip(urlReader(url)))
}

object AddonArchive {
  def read[F[_]: Async: Files](
      url: LenientUri,
      urlReader: UrlReader[F],
      extractDir: Option[Path] = None
  ): F[AddonArchive] = {
    val addon = AddonArchive(url, "", "")
    addon
      .readMeta(urlReader, extractDir)
      .map(m => addon.copy(name = m.meta.name, version = m.meta.version))
  }

  def dockerAndFlakeExists[F[_]: Async: Files](
      archive: Either[Path, Stream[F, Byte]]
  ): F[(Boolean, Boolean)] = {
    val files = Files[F]
    val logger = docspell.logging.getLogger[F]
    def forPath(path: Path): F[(Boolean, Boolean)] =
      (files.exists(path / "Dockerfile"), files.exists(path / "flake.nix")).tupled

    def forZip(data: Stream[F, Byte]): F[(Boolean, Boolean)] =
      data
        .through(Zip[F](logger.some).unzip(glob = Glob("Dockerfile|flake.nix")))
        .collect {
          case bin if bin.name == "Dockerfile" => (true, false)
          case bin if bin.name == "flake.nix"  => (false, true)
        }
        .compile
        .fold((false, false))((r, e) => (r._1 || e._1, r._2 || e._2))

    archive.fold(forPath, forZip)
  }
}
