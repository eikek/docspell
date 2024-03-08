/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.ocr

import cats.effect._
import fs2.Stream
import fs2.io.file.{Files, Path}

import docspell.common.exec.ExternalCommand
import docspell.common.exec.SysExec
import docspell.common.util.File
import docspell.logging.Logger

object Ocr {

  /** Extract the text of all pages in the given pdf file. */
  def extractPdf[F[_]: Async: Files](
      pdf: Stream[F, Byte],
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): F[Option[String]] =
    File.withTempDir(config.ghostscript.workingDir, "extractpdf").use { wd =>
      runGhostscript(pdf, config, wd, logger)
        .flatMap(tmpImg => runTesseractFile(tmpImg, logger, lang, config))
        .fold1(_ + "\n\n\n" + _)
        .compile
        .last
    }

  /** Extract the text from the given image file */
  def extractImage[F[_]: Async](
      img: Stream[F, Byte],
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, String] =
    runTesseractStdin(img, logger, lang, config)

  def extractPdFFile[F[_]: Async: Files](
      pdf: Path,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): F[Option[String]] =
    File.withTempDir(config.ghostscript.workingDir, "extractpdf").use { wd =>
      runGhostscriptFile(pdf, config.ghostscript.command, wd, logger)
        .flatMap(tif => runTesseractFile(tif, logger, lang, config))
        .fold1(_ + "\n\n\n" + _)
        .compile
        .last
    }

  def extractImageFile[F[_]: Async](
      img: Path,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, String] =
    runTesseractFile(img, logger, lang, config)

  /** Run ghostscript to extract all pdf pages into tiff files. The files are stored to a
    * temporary location on disk and returned.
    */
  private[extract] def runGhostscript[F[_]: Async: Files](
      pdf: Stream[F, Byte],
      cfg: OcrConfig,
      wd: Path,
      logger: Logger[F]
  ): Stream[F, Path] = {
    val xargs =
      if (cfg.pageRange.begin > 0)
        s"-dLastPage=${cfg.pageRange.begin}" +: cfg.ghostscript.command.args
      else cfg.ghostscript.command.args
    val cmd = cfg.ghostscript.command
      .copy(args = xargs)
      .withVars(
        Map(
          "infile" -> "-",
          "outfile" -> "%d.tif"
        )
      )
      .resolved

    Stream
      .resource(SysExec(cmd, logger, Some(wd), Some(pdf)))
      .evalMap(_.runToSuccess(logger))
      .flatMap(_ => File.listFiles(pathEndsWith(".tif"), wd))
  }

  /** Run ghostscript to extract all pdf pages into tiff files. The files are stored to a
    * temporary location on disk and returned.
    */
  private[extract] def runGhostscriptFile[F[_]: Async: Files](
      pdf: Path,
      ghostscript: ExternalCommand,
      wd: Path,
      logger: Logger[F]
  ): Stream[F, Path] = {
    val cmd = ghostscript
      .withVars(
        Map(
          "infile" -> pdf.absolute.toString,
          "outfile" -> "%d.tif"
        )
      )
      .resolved

    Stream
      .resource(SysExec(cmd, logger, Some(wd)))
      .evalMap(_.runToSuccess(logger))
      .flatMap(_ => File.listFiles(pathEndsWith(".tif"), wd))
  }

  private def pathEndsWith(ext: String): Path => Boolean =
    p => p.fileName.toString.endsWith(ext)

  /** Run unpaper to optimize the image for ocr. The files are stored to a temporary
    * location on disk and returned.
    */
  private[extract] def runUnpaperFile[F[_]: Async](
      img: Path,
      unpaper: ExternalCommand,
      wd: Option[Path],
      logger: Logger[F]
  ): Stream[F, Path] = {
    val targetFile = img.resolveSibling("u-" + img.fileName.toString).absolute
    val cmd = unpaper
      .withVars(
        Map(
          "infile" -> img.absolute.toString,
          "outfile" -> targetFile.toString
        )
      )
      .resolved

    Stream
      .resource(SysExec(cmd, logger, wd))
      .evalMap(_.runToSuccess(logger))
      .map(_ => targetFile)
      .handleErrorWith { th =>
        logger
          .warn(
            s"Unpaper command failed: ${th.getMessage}. Using input file for text extraction."
          )
        Stream.emit(img)
      }
  }

  /** Run tesseract on the given image file and return the extracted text. */
  private[extract] def runTesseractFile[F[_]: Async](
      img: Path,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, String] =
    // tesseract cannot cope with absolute filenames
    // so use the parent as working dir
    runUnpaperFile(img, config.unpaper.command, img.parent, logger).flatMap { uimg =>
      val cmd = config.tesseract.command
        .withVars(
          Map("file" -> uimg.fileName.toString, "lang" -> fixLanguage(lang))
        )
        .resolved

      Stream
        .resource(SysExec(cmd, logger, uimg.parent))
        .evalMap(_.runToSuccessStdout(logger))
    }

  /** Run tesseract on the given image file and return the extracted text. */
  private[extract] def runTesseractStdin[F[_]: Async](
      img: Stream[F, Byte],
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, String] = {
    val cmd = config.tesseract.command
      .withVars(Map("file" -> "stdin", "lang" -> fixLanguage(lang)))
      .resolved

    Stream
      .resource(SysExec(cmd, logger, None, Some(img)))
      .evalMap(_.runToSuccessStdout(logger))
  }

  private def fixLanguage(lang: String): String =
    lang match {
      case "de" => "deu"
      case "en" => "eng"
      case l    => l
    }
}
