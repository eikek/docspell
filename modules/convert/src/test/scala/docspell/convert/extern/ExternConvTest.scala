package docspell.convert.extern

import java.nio.file.{Path, Paths}

import cats.effect._
import docspell.common._
import docspell.convert._
import docspell.files.{ExampleFiles, TestFiles}
import minitest.SimpleTestSuite
import java.nio.charset.StandardCharsets

object ExternConvTest extends SimpleTestSuite with FileChecks {
  val blocker     = TestFiles.blocker
  implicit val CS = TestFiles.CS
  val utf8        = StandardCharsets.UTF_8
  val logger      = Logger.log4s[IO](org.log4s.getLogger)
  val target      = Paths.get("target")

  test("convert html to pdf") {
    val cfg = SystemCommand.Config(
      "wkhtmltopdf",
      Seq("-s", "A4", "--encoding", "UTF-8", "-", "{{outfile}}"),
      Duration.seconds(20)
    )

    if (!commandExists(cfg.program)) ignore(s"Command ${cfg.program} not found")
    else
      File
        .withTempDir[IO](target, "wkhtmltopdf")
        .use(dir =>
          IO {
            val wkCfg = WkHtmlPdfConfig(cfg, target)
            val p =
              WkHtmlPdf
                .toPDF[IO, Path](wkCfg, 8192, utf8, SanitizeHtml.none, blocker, logger)(
                  ExampleFiles.letter_de_html.readURL[IO](8192, blocker),
                  storePdfHandler(dir.resolve("test.pdf"))
                )
                .unsafeRunSync()

            assert(p.isNonEmpty && p.isPDF)
          }
        )
        .unsafeRunSync()
  }

  test("convert office to pdf") {
    val cfg = SystemCommand.Config(
      "unoconv",
      Seq("-f", "pdf", "-o", "{{outfile}}", "{{infile}}"),
      Duration.seconds(20)
    )

    if (!commandExists(cfg.program)) ignore(s"Command ${cfg.program} not found")
    else
      File
        .withTempDir[IO](target, "unoconv")
        .use(dir =>
          IO {
            val ucCfg = UnoconvConfig(cfg, target)
            val p =
              Unoconv
                .toPDF[IO, Path](ucCfg, 8192, blocker, logger)(
                  ExampleFiles.examples_sample_docx.readURL[IO](8192, blocker),
                  storePdfHandler(dir.resolve("test.pdf"))
                )
                .unsafeRunSync()

            assert(p.isNonEmpty && p.isPDF)
          }
        )
        .unsafeRunSync()
  }

  test("convert image to pdf") {
    val cfg = SystemCommand.Config(
      "tesseract",
      Seq("{{infile}}", "out", "-l", "deu", "pdf", "txt"),
      Duration.seconds(20)
    )

    if (!commandExists(cfg.program)) ignore(s"Command ${cfg.program} not found")
    else
      File
        .withTempDir[IO](target, "tesseract")
        .use(dir =>
          IO {
            val tessCfg = TesseractConfig(cfg, target)
            val (pdf, txt) =
              Tesseract
                .toPDF[IO, (Path, Path)](tessCfg, Language.German, 8192, blocker, logger)(
                  ExampleFiles.camera_letter_en_jpg.readURL[IO](8192, blocker),
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
