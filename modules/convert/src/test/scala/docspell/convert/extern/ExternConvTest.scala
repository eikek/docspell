/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert.extern

import java.nio.charset.StandardCharsets
import java.nio.file.Paths

import cats.effect._
import cats.effect.unsafe.implicits.global
import fs2.io.file.Path

import docspell.common._
import docspell.common.exec._
import docspell.common.util.File
import docspell.convert._
import docspell.files.ExampleFiles
import docspell.logging.TestLoggingConfig

import munit._

class ExternConvTest extends FunSuite with FileChecks with TestLoggingConfig {
  val utf8 = StandardCharsets.UTF_8
  val logger = docspell.logging.getLogger[IO]
  val target = File.path(Paths.get("target"))

  test("convert html to pdf") {
    val cfg = ExternalCommand(
      "wkhtmltopdf",
      Seq("-s", "A4", "--encoding", "UTF-8", "-", "{{outfile}}"),
      Duration.seconds(20)
    )
    assume(commandExists(cfg.program), s"Command ${cfg.program} not found. Ignore tests.")
    File
      .withTempDir[IO](target, "wkhtmltopdf")
      .use(dir =>
        IO {
          val wkCfg = WkHtmlPdfConfig(cfg, target)
          val p =
            WkHtmlPdf
              .toPDF[IO, Path](wkCfg, 8192, utf8, SanitizeHtml.none, logger)(
                ExampleFiles.letter_de_html.readURL[IO](8192),
                storePdfHandler(dir.resolve("test.pdf"))
              )
              .unsafeRunSync()

          assert(p.isNonEmpty && p.isPDF)
        }
      )
      .unsafeRunSync()
  }

  test("convert office to pdf") {
    val cfg = ExternalCommand(
      "unoconv",
      Seq("-f", "pdf", "-o", "{{outfile}}", "{{infile}}"),
      Duration.seconds(20)
    )

    assume(commandExists(cfg.program), s"Command ${cfg.program} not found. Ignore tests.")
    File
      .withTempDir[IO](target, "unoconv")
      .use(dir =>
        IO {
          val ucCfg = UnoconvConfig(cfg, target)
          val p =
            Unoconv
              .toPDF[IO, Path](ucCfg, 8192, logger)(
                ExampleFiles.examples_sample_docx.readURL[IO](8192),
                storePdfHandler(dir.resolve("test.pdf"))
              )
              .unsafeRunSync()

          assert(p.isNonEmpty && p.isPDF)
        }
      )
      .unsafeRunSync()
  }

  test("convert image to pdf") {
    val cfg = ExternalCommand(
      "tesseract",
      Seq("{{infile}}", "out", "-l", "deu", "pdf", "txt"),
      Duration.seconds(20)
    )
    assume(commandExists(cfg.program), s"Command ${cfg.program} not found")
    File
      .withTempDir[IO](target, "tesseract")
      .use(dir =>
        IO {
          val tessCfg = TesseractConfig(cfg, target)
          val (pdf, txt) =
            Tesseract
              .toPDF[IO, (Path, Path)](tessCfg, Language.German, 8192, logger)(
                ExampleFiles.camera_letter_en_jpg.readURL[IO](8192),
                storePdfTxtHandler(dir.resolve("test.pdf"), dir.resolve("test.txt"))
              )
              .unsafeRunSync()

          assert(pdf.isNonEmpty && pdf.isPDF)
          assert(txt.isNonEmpty && txt.isPlainText)
        }
      )
      .unsafeRunSync()
  }
}
