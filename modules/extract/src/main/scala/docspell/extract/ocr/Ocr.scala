package docspell.extract.ocr

import java.nio.file.Path

import cats.effect.{Blocker, ContextShift, Sync}
import fs2.Stream
import docspell.common._

object Ocr {

  /** Extract the text of all pages in the given pdf file.
    */
  def extractPdf[F[_]: Sync: ContextShift](
      pdf: Stream[F, Byte],
      blocker: Blocker,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): F[Option[String]] =
    File.withTempDir(config.ghostscript.workingDir, "extractpdf").use { wd =>
      runGhostscript(pdf, config, wd, blocker, logger)
        .flatMap({ tmpImg =>
          runTesseractFile(tmpImg, blocker, logger, lang, config)
        })
        .fold1(_ + "\n\n\n" + _).
        compile.
        last
    }

  /** Extract the text from the given image file
    */
  def extractImage[F[_]: Sync: ContextShift](
      img: Stream[F, Byte],
      blocker: Blocker,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, String] =
    runTesseractStdin(img, blocker, logger, lang, config)

  def extractPdFFile[F[_]: Sync: ContextShift](
      pdf: Path,
      blocker: Blocker,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): F[Option[String]] =
    File.withTempDir(config.ghostscript.workingDir, "extractpdf").use { wd =>
      runGhostscriptFile(pdf, config.ghostscript.command, wd, blocker, logger)
        .flatMap({ tif =>
          runTesseractFile(tif, blocker, logger, lang, config)
        })
        .fold1(_ + "\n\n\n" + _).
        compile.
        last
    }

  def extractImageFile[F[_]: Sync: ContextShift](
      img: Path,
      blocker: Blocker,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, String] =
    runTesseractFile(img, blocker, logger, lang, config)

  /** Run ghostscript to extract all pdf pages into tiff files. The
    * files are stored to a temporary location on disk and returned.
    */
  private[extract] def runGhostscript[F[_]: Sync: ContextShift](
                                                                 pdf: Stream[F, Byte],
                                                                 cfg: OcrConfig,
                                                                 wd: Path,
                                                                 blocker: Blocker,
                                                                 logger: Logger[F]
  ): Stream[F, Path] = {
    val xargs =
      if (cfg.pageRange.begin > 0)
        s"-dLastPage=${cfg.pageRange.begin}" +: cfg.ghostscript.command.args
      else cfg.ghostscript.command.args
    val cmd = cfg.ghostscript.command
      .copy(args = xargs)
      .mapArgs(
        replace(
          Map(
            "{{infile}}"  -> "-",
            "{{outfile}}" -> "%d.tif"
          )
        )
      )
    SystemCommand
      .execSuccess(cmd, blocker, logger, wd = Some(wd), stdin = pdf)
      .evalMap({ _ =>
        File.listFiles(pathEndsWith(".tif"), wd)
      })
      .flatMap(fs => Stream.emits(fs))
  }

  /** Run ghostscript to extract all pdf pages into tiff files. The
    * files are stored to a temporary location on disk and returned.
    */
  private[extract] def runGhostscriptFile[F[_]: Sync: ContextShift](
      pdf: Path,
      ghostscript: SystemCommand.Config,
      wd: Path,
      blocker: Blocker,
      logger: Logger[F]
  ): Stream[F, Path] = {
    val cmd = ghostscript.mapArgs(
      replace(
        Map(
          "{{infile}}"  -> pdf.toAbsolutePath.toString,
          "{{outfile}}" -> "%d.tif"
        )
      )
    )
    SystemCommand
      .execSuccess[F](cmd, blocker, logger, wd = Some(wd))
      .evalMap({ _ =>
        File.listFiles(pathEndsWith(".tif"), wd)
      })
      .flatMap(fs => Stream.emits(fs))
  }

  private def pathEndsWith(ext: String): Path => Boolean =
    p => p.getFileName.toString.endsWith(ext)

  /** Run unpaper to optimize the image for ocr. The
    * files are stored to a temporary location on disk and returned.
    */
  private[extract] def runUnpaperFile[F[_]: Sync: ContextShift](
      img: Path,
      unpaper: SystemCommand.Config,
      wd: Path,
      blocker: Blocker,
      logger: Logger[F]
  ): Stream[F, Path] = {
    val targetFile = img.resolveSibling("u-" + img.getFileName.toString).toAbsolutePath
    val cmd = unpaper.mapArgs(
      replace(
        Map(
          "{{infile}}"  -> img.toAbsolutePath.toString,
          "{{outfile}}" -> targetFile.toString
        )
      )
    )
    SystemCommand.execSuccess[F](cmd, blocker, logger, wd = Some(wd)).map(_ => targetFile).handleErrorWith {
      th =>
        logger
          .warn(s"Unpaper command failed: ${th.getMessage}. Using input file for text extraction.")
        Stream.emit(img)
    }
  }

  /** Run tesseract on the given image file and return the extracted
    * text.
    */
  private[extract] def runTesseractFile[F[_]: Sync: ContextShift](
      img: Path,
      blocker: Blocker,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, String] =
    // tesseract cannot cope with absolute filenames
    // so use the parent as working dir
    runUnpaperFile(img, config.unpaper.command, img.getParent, blocker, logger).flatMap { uimg =>
      val cmd = config.tesseract.command.mapArgs(
        replace(Map("{{file}}" -> uimg.getFileName.toString, "{{lang}}" -> fixLanguage(lang)))
      )
      SystemCommand.execSuccess[F](cmd, blocker, logger, wd = Some(uimg.getParent)).map(_.stdout)
    }

  /** Run tesseract on the given image file and return the extracted
    * text.
    */
  private[extract] def runTesseractStdin[F[_]: Sync: ContextShift](
      img: Stream[F, Byte],
      blocker: Blocker,
      logger: Logger[F],
      lang: String,
      config: OcrConfig
  ): Stream[F, String] = {
    val cmd = config.tesseract.command
      .mapArgs(replace(Map("{{file}}" -> "stdin", "{{lang}}" -> fixLanguage(lang))))
    SystemCommand.execSuccess(cmd, blocker, logger, stdin = img).map(_.stdout)
  }

  private def replace(repl: Map[String, String]): String => String =
    s =>
      repl.foldLeft(s) {
        case (res, (k, v)) =>
          res.replace(k, v)
      }

  private def fixLanguage(lang: String): String =
    lang match {
      case "de" => "deu"
      case "en" => "eng"
      case l    => l
    }
}
