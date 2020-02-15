package docspell.extract.ocr

import java.nio.file.Path

import cats.effect.{Blocker, ContextShift, Sync}
import fs2.Stream
import org.log4s._
import docspell.common._

object Ocr {
  private[this] val logger = getLogger

  /** Extract the text of all pages in the given pdf file.
    */
  def extractPdf[F[_]: Sync: ContextShift](
      pdf: Stream[F, Byte],
      blocker: Blocker,
      lang: String,
      config: Config
  ): Stream[F, String] =
    File.withTempDir(config.ghostscript.workingDir, "extractpdf") { wd =>
      runGhostscript(pdf, config, wd, blocker)
        .flatMap({ tmpImg =>
          runTesseractFile(tmpImg, blocker, lang, config)
        })
        .fold1(_ + "\n\n\n" + _)
    }

  /** Extract the text from the given image file
    */
  def extractImage[F[_]: Sync: ContextShift](
      img: Stream[F, Byte],
      blocker: Blocker,
      lang: String,
      config: Config
  ): Stream[F, String] =
    runTesseractStdin(img, blocker, lang, config)

  def extractPdFFile[F[_]: Sync: ContextShift](
      pdf: Path,
      blocker: Blocker,
      lang: String,
      config: Config
  ): Stream[F, String] =
    File.withTempDir(config.ghostscript.workingDir, "extractpdf") { wd =>
      runGhostscriptFile(pdf, config.ghostscript.command, wd, blocker)
        .flatMap({ tif =>
          runTesseractFile(tif, blocker, lang, config)
        })
        .fold1(_ + "\n\n\n" + _)
    }

  def extractImageFile[F[_]: Sync: ContextShift](
      img: Path,
      blocker: Blocker,
      lang: String,
      config: Config
  ): Stream[F, String] =
    runTesseractFile(img, blocker, lang, config)

  /** Run ghostscript to extract all pdf pages into tiff files. The
    * files are stored to a temporary location on disk and returned.
    */
  private[extract] def runGhostscript[F[_]: Sync: ContextShift](
      pdf: Stream[F, Byte],
      cfg: Config,
      wd: Path,
      blocker: Blocker
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
      .execSuccess(cmd, blocker, wd = Some(wd), stdin = pdf)
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
      blocker: Blocker
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
      .execSuccess[F](cmd, blocker, wd = Some(wd))
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
      blocker: Blocker
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
    SystemCommand.execSuccess[F](cmd, blocker, wd = Some(wd)).map(_ => targetFile).handleErrorWith {
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
      lang: String,
      config: Config
  ): Stream[F, String] =
    // tesseract cannot cope with absolute filenames
    // so use the parent as working dir
    runUnpaperFile(img, config.unpaper.command, img.getParent, blocker).flatMap { uimg =>
      val cmd = config.tesseract.command.mapArgs(
        replace(Map("{{file}}" -> uimg.getFileName.toString, "{{lang}}" -> fixLanguage(lang)))
      )
      SystemCommand.execSuccess[F](cmd, blocker, wd = Some(uimg.getParent)).map(_.stdout)
    }

  /** Run tesseract on the given image file and return the extracted
    * text.
    */
  private[extract] def runTesseractStdin[F[_]: Sync: ContextShift](
      img: Stream[F, Byte],
      blocker: Blocker,
      lang: String,
      config: Config
  ): Stream[F, String] = {
    val cmd = config.tesseract.command
      .mapArgs(replace(Map("{{file}}" -> "stdin", "{{lang}}" -> fixLanguage(lang))))
    SystemCommand.execSuccess(cmd, blocker, stdin = img).map(_.stdout)
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
