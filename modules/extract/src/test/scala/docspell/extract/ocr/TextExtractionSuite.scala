/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.ocr

import java.nio.file.Paths

import cats.effect.IO
import cats.effect.unsafe.implicits.global

import docspell.common.Duration
import docspell.common.exec.ExternalCommand
import docspell.common.util.File
import docspell.files.TestFiles
import docspell.logging.TestLoggingConfig

import munit._

class TextExtractionSuite extends FunSuite with TestLoggingConfig {
  import TestFiles._

  val logger = docspell.logging.getLogger[IO]

  test("extract english pdf".ignore) {
    val text = TextExtract
      .extract[IO](letterSourceEN, logger, "eng", TextExtractionSuite.defaultConfig)
      .compile
      .lastOrError
      .unsafeRunSync()
    println(text)
  }

  test("extract german pdf".ignore) {
    val expect = TestFiles.letterDEText
    val extract = TextExtract
      .extract[IO](letterSourceDE, logger, "deu", TextExtractionSuite.defaultConfig)
      .compile
      .lastOrError
      .unsafeRunSync()

    assertEquals(extract.value, expect)
  }
}

object TextExtractionSuite {
  val defaultConfig = OcrConfig(
    maxImageSize = 3000 * 3000,
    pageRange = OcrConfig.PageRange(10),
    ghostscript = OcrConfig.Ghostscript(
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
    unpaper = OcrConfig.Unpaper(
      ExternalCommand("unpaper", Seq("{{infile}}", "{{outfile}}"), Duration.seconds(30))
    ),
    tesseract = OcrConfig.Tesseract(
      ExternalCommand(
        "tesseract",
        Seq("{{file}}", "stdout", "-l", "{{lang}}"),
        Duration.minutes(1)
      )
    )
  )
}
