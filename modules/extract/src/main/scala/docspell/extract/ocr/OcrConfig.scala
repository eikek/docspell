/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.ocr

import java.nio.file.Paths

import fs2.io.file.Path

import docspell.common._
import docspell.common.exec.ExternalCommand
import docspell.common.util.File

case class OcrConfig(
    maxImageSize: Int,
    ghostscript: OcrConfig.Ghostscript,
    pageRange: OcrConfig.PageRange,
    unpaper: OcrConfig.Unpaper,
    tesseract: OcrConfig.Tesseract
) {}

object OcrConfig {

  case class PageRange(begin: Int)

  case class Ghostscript(command: ExternalCommand, workingDir: Path)

  case class Tesseract(command: ExternalCommand)

  case class Unpaper(command: ExternalCommand)

  val default = OcrConfig(
    maxImageSize = 3000 * 3000,
    pageRange = PageRange(10),
    ghostscript = Ghostscript(
      ExternalCommand(
        "gs",
        Seq(
          "-dNOPAUSE",
          "-dBATCH",
          "-dSAFER",
          "-sDEVICE=tiffscaled8",
          "-sOutputFile={{outfile}}",
          "{{infile}}"
        ),
        Duration.seconds(30)
      ),
      File.path(
        Paths.get(System.getProperty("java.io.tmpdir")).resolve("docspell-extraction")
      )
    ),
    unpaper = Unpaper(
      ExternalCommand("unpaper", Seq("{{infile}}", "{{outfile}}"), Duration.seconds(30))
    ),
    tesseract = Tesseract(
      ExternalCommand(
        "tesseract",
        Seq("{{file}}", "stdout", "-l", "{{lang}}"),
        Duration.minutes(1)
      )
    )
  )
}
