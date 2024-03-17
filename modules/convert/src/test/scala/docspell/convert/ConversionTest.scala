/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert

import java.nio.file.Paths

import cats.data.Kleisli
import cats.effect.IO
import cats.effect.unsafe.implicits.global
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.common.exec._
import docspell.common.util.File
import docspell.convert.ConversionResult.Handler
import docspell.convert.ConvertConfig.HtmlConverter
import docspell.convert.extern._
import docspell.convert.flexmark.MarkdownConfig
import docspell.files.ExampleFiles
import docspell.logging.TestLoggingConfig

import munit._

class ConversionTest extends FunSuite with FileChecks with TestLoggingConfig {

  val logger = docspell.logging.getLogger[IO]
  val target = File.path(Paths.get("target"))

  val convertConfig = ConvertConfig(
    8192,
    "converted",
    3000 * 3000,
    MarkdownConfig("body { padding: 2em 5em; }"),
    WkHtmlPdfConfig(
      ExternalCommand(
        "wkhtmltopdf",
        Seq("-s", "A4", "--encoding", "UTF-8", "-", "{{outfile}}"),
        Duration.seconds(20)
      ),
      target
    ),
    WeasyprintConfig(
      ExternalCommand(
        "weasyprint",
        Seq("--encoding", "UTF-8", "-", "{{outfile}}"),
        Duration.seconds(20)
      ),
      target
    ),
    HtmlConverter.Wkhtmltopdf,
    TesseractConfig(
      ExternalCommand(
        "tesseract",
        Seq("{{infile}}", "out", "-l", "deu", "pdf", "txt"),
        Duration.seconds(20)
      ),
      target
    ),
    UnoconvConfig(
      ExternalCommand(
        "unoconv",
        Seq("-f", "pdf", "-o", "{{outfile}}", "{{infile}}"),
        Duration.seconds(20)
      ),
      target
    ),
    OcrMyPdfConfig(
      enabled = true,
      ExternalCommand(
        "ocrmypdf",
        Seq(
          "-l",
          "{{lang}}",
          "--skip-text",
          "--deskew",
          "-j",
          "1",
          "{{infile}}",
          "{{outfile}}"
        ),
        Duration.seconds(20)
      ),
      target
    ),
    ConvertConfig.DecryptPdf(enabled = true, Nil)
  )

  val conversion =
    Conversion.create[IO](convertConfig, SanitizeHtml.none, Nil, logger)

  val bombs = List(
    ExampleFiles.bombs_20K_gray_jpeg,
    ExampleFiles.bombs_20K_gray_png,
    ExampleFiles.bombs_20K_rgb_jpeg,
    ExampleFiles.bombs_20K_rgb_png
  )
  val pdfOnly = List(
    ExampleFiles.examples_sample_ods,
    ExampleFiles.examples_sample_doc,
    ExampleFiles.examples_sample_docx,
    ExampleFiles.examples_sample_ods,
    ExampleFiles.examples_sample_odt,
    ExampleFiles.examples_sample_rtf,
    ExampleFiles.examples_sample_xls,
    ExampleFiles.examples_sample_xlsx,
    ExampleFiles.letter_de_md,
    ExampleFiles.letter_de_txt,
    ExampleFiles.letter_en_txt,
    ExampleFiles.letter_de_html
  )
  val pdfAndTxt = List(
    ExampleFiles.camera_letter_en_jpg,
    ExampleFiles.camera_letter_en_png,
    ExampleFiles.camera_letter_en_tiff,
    ExampleFiles.scanner_jfif_jpg
  )

  test("convert to pdf") {
    assume(commandsExist, "At least one of the conversion programs not found")

    File
      .withTempDir[IO](target, "convpdf")
      .use { dir =>
        conversion.use { conv =>
          def check(n: Long): Handler[IO, Unit] =
            storePdfHandler(dir.resolve(s"test-$n.pdf")).map { p =>
              assert(p.isNonEmpty && p.isPDF)
            }

          runConversion(pdfOnly, check, conv).compile.drain
        }
      }
      .unsafeRunSync()
  }

  test("convert image to pdf and txt") {
    assume(commandsExist, "At least one of the conversion programs not found")
    File
      .withTempDir[IO](target, "convimgpdf")
      .use { dir =>
        conversion.use { conv =>
          def check(n: Long): Handler[IO, Unit] =
            storePdfTxtHandler(dir.resolve(s"test-$n.pdf"), dir.resolve(s"test-$n.txt"))
              .map { case (p, t) =>
                assert(p.isNonEmpty && p.isPDF)
                assert(t.isNonEmpty && t.isPlainText)
              }

          runConversion(pdfAndTxt, check, conv).compile.drain
        }
      }
      .unsafeRunSync()
  }

  test("do not convert image bombs") {
    assume(commandsExist, "At least one of the conversion programs not found")

    conversion
      .use { conv =>
        def check: Handler[IO, Unit] =
          Kleisli {
            case ConversionResult.InputMalformed(_, _) =>
              ().pure[IO]
            case cr =>
              IO.raiseError(new Exception(s"Unexpected result: $cr"))
          }

        runConversion(bombs, _ => check, conv).compile.drain
      }
      .unsafeRunSync()
  }

  def runConversion[A](
      uris: List[LenientUri],
      handler: Long => Handler[IO, A],
      conv: Conversion[IO]
  ) =
    Stream
      .emits(uris)
      .covary[IO]
      .zipWithIndex
      .evalMap { case (uri, index) =>
        val load = uri.readURL[IO](8192)
        val dataType = DataType.filename(uri.path.segments.last)
        logger.info(s"Processing file ${uri.path.asString}") *>
          conv.toPDF(dataType, Language.German, handler(index))(load)
      }

  def commandsExist: Boolean =
    commandExists(convertConfig.unoconv.command.program) &&
      commandExists(convertConfig.wkhtmlpdf.command.program) &&
      commandExists(convertConfig.tesseract.command.program)
}
