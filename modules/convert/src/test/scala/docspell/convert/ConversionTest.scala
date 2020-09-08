package docspell.convert

import java.nio.file.Paths

import cats.data.Kleisli
import cats.implicits._
import cats.effect.IO
import fs2.Stream
import docspell.common._
import docspell.convert.ConversionResult.Handler
import docspell.convert.extern.{TesseractConfig, UnoconvConfig, WkHtmlPdfConfig}
import docspell.convert.flexmark.MarkdownConfig
import docspell.files.{ExampleFiles, TestFiles}
import minitest.SimpleTestSuite
import docspell.convert.extern.OcrMyPdfConfig

object ConversionTest extends SimpleTestSuite with FileChecks {
  val blocker     = TestFiles.blocker
  implicit val CS = TestFiles.CS

  val logger = Logger.log4s[IO](org.log4s.getLogger)
  val target = Paths.get("target")

  val convertConfig = ConvertConfig(
    8192,
    3000 * 3000,
    MarkdownConfig("body { padding: 2em 5em; }"),
    WkHtmlPdfConfig(
      SystemCommand.Config(
        "wkhtmltopdf",
        Seq("-s", "A4", "--encoding", "UTF-8", "-", "{{outfile}}"),
        Duration.seconds(20)
      ),
      target
    ),
    TesseractConfig(
      SystemCommand.Config(
        "tesseract",
        Seq("{{infile}}", "out", "-l", "deu", "pdf", "txt"),
        Duration.seconds(20)
      ),
      target
    ),
    UnoconvConfig(
      SystemCommand.Config(
        "unoconv",
        Seq("-f", "pdf", "-o", "{{outfile}}", "{{infile}}"),
        Duration.seconds(20)
      ),
      target
    ),
    OcrMyPdfConfig(
      true,
      SystemCommand.Config(
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
    )
  )

  val conversion =
    Conversion.create[IO](convertConfig, SanitizeHtml.none, blocker, logger)

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
    if (!commandsExist) ignore("At least one of the conversion programs not found")
    else
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
    if (!commandsExist) ignore("At least one of the conversion programs not found")
    else
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
    if (!commandsExist) ignore("At least one of the conversion programs not found")
    else
      conversion
        .use { conv =>
          def check: Handler[IO, Unit] =
            Kleisli({
              case ConversionResult.InputMalformed(_, _) =>
                ().pure[IO]
              case cr =>
                IO.raiseError(new Exception(s"Unexpected result: $cr"))
            })

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
      .evalMap({ case (uri, index) =>
        val load     = uri.readURL[IO](8192, blocker)
        val dataType = DataType.filename(uri.path.segments.last)
        logger.info(s"Processing file ${uri.path.asString}") *>
          conv.toPDF(dataType, Language.German, handler(index))(load)
      })

  def commandsExist: Boolean =
    commandExists(convertConfig.unoconv.command.program) &&
      commandExists(convertConfig.wkhtmlpdf.command.program) &&
      commandExists(convertConfig.tesseract.command.program)
}
