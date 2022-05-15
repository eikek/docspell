/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons.out

import cats.data.OptionT
import cats.effect._
import cats.syntax.all._
import fs2.io.file.{Files, Path}

import docspell.common._
import docspell.files.FileSupport._
import docspell.logging.Logger

import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.{deriveConfiguredDecoder, deriveConfiguredEncoder}
import io.circe.{Decoder, Encoder}

/** Addons can produce files in their output directory. These can be named here in order
  * to do something with them.
  *
  *   - textFiles will replace the extracted text with the contents of the file
  *   - pdfFiles will add/replace the converted pdf with the given file
  *   - previewImages will add/replace preview images
  *   - newFiles will be added as new attachments to the item
  *
  * Files must be referenced by attachment id.
  */
final case class ItemFile(
    itemId: Ident,
    textFiles: Map[String, String] = Map.empty,
    pdfFiles: Map[String, String] = Map.empty,
    previewImages: Map[String, String] = Map.empty,
    newFiles: List[NewFile] = Nil
) {
  def isEmpty: Boolean =
    textFiles.isEmpty && pdfFiles.isEmpty && previewImages.isEmpty

  def nonEmpty: Boolean = !isEmpty

  def resolveTextFiles[F[_]: Files: Sync](
      logger: Logger[F],
      outputDir: Path
  ): F[List[(String, Path)]] =
    resolveFiles(logger, outputDir, MimeType.text("*"), textFiles)

  def resolvePdfFiles[F[_]: Files: Sync](
      logger: Logger[F],
      outputDir: Path
  ): F[List[(String, Path)]] =
    resolveFiles(logger, outputDir, MimeType.pdf, pdfFiles)

  def resolvePreviewFiles[F[_]: Files: Sync](
      logger: Logger[F],
      outputDir: Path
  ): F[List[(String, Path)]] =
    resolveFiles(logger, outputDir, MimeType.image("*"), previewImages)

  def resolveNewFiles[F[_]: Files: Sync](
      logger: Logger[F],
      outputDir: Path
  ): F[List[(NewFile, Path)]] =
    newFiles.traverseFilter(nf =>
      nf.resolveFile(logger, outputDir).map(_.map(p => (nf, p)))
    )

  private def resolveFiles[F[_]: Files: Sync](
      logger: Logger[F],
      outputDir: Path,
      mime: MimeType,
      files: Map[String, String]
  ): F[List[(String, Path)]] = {
    val allFiles =
      files.toList.map(t => t._1 -> outputDir / t._2)

    allFiles.traverseFilter { case (key, file) =>
      OptionT(file.detectMime)
        .flatMapF(fileType =>
          if (mime.matches(fileType)) (key -> file).some.pure[F]
          else
            logger
              .warn(
                s"File $file provided as ${mime.asString} file, but was recognized as ${fileType.asString}. Ignoring it."
              )
              .as(None: Option[(String, Path)])
        )
        .value
    }
  }
}

object ItemFile {

  implicit val jsonConfig: Configuration =
    Configuration.default.withDefaults

  implicit val jsonEncoder: Encoder[ItemFile] = deriveConfiguredEncoder
  implicit val jsonDecoder: Decoder[ItemFile] = deriveConfiguredDecoder
}
