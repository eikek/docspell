package docspell.convert.extern

import java.nio.file.{Files, Path, Paths}

import fs2.Stream
import cats.effect._
import docspell.common._
import docspell.files.{ExampleFiles, TestFiles}
import fs2.Pipe
import minitest.SimpleTestSuite

object ExternConvTest extends SimpleTestSuite {
  val blocker     = TestFiles.blocker
  implicit val CS = TestFiles.CS

  val logger = Logger.log4s[IO](org.log4s.getLogger)
  val target = Paths.get("target")


  test("convert html to pdf") {
    val cfg = SystemCommand.Config(
      "wkhtmltopdf",
      Seq("-s", "A4", "--encoding", "UTF-8", "-", "{{outfile}}"),
      Duration.seconds(20)
    )

    if (!commandExists(cfg.program)) ignore(s"Command ${cfg.program} not found")
    else {
      File
        .withTempDir[IO](target, "wkhtmltopdf")
        .use(dir => IO {
          val wkCfg = WkHtmlPdfConfig(cfg, target)
          val p = ExampleFiles.letter_de_html
            .readURL[IO](8192, blocker)
            .through(WkHtmlPdf.toPDF[IO](wkCfg, 8192, blocker, logger))
            .through(storeFile(dir.resolve("test.pdf")))
            .compile
            .lastOrError
            .unsafeRunSync()

          assert(Files.exists(p) && Files.size(p) > 0)
        })
        .unsafeRunSync
    }
  }

  test("convert office to pdf") {
    val cfg = SystemCommand.Config(
      "unoconv",
      Seq("-f", "pdf", "-o", "{{outfile}}", "{{infile}}"),
      Duration.seconds(20)
    )

    if (!commandExists(cfg.program)) ignore(s"Command ${cfg.program} not found")
    else {
      File
        .withTempDir[IO](target, "unoconv")
        .use(dir => IO {
          val ucCfg = UnoconvConfig(cfg, target)
          val p = ExampleFiles.examples_sample_docx
            .readURL[IO](8192, blocker)
            .through(Unoconv.toPDF[IO](ucCfg, 8192, blocker, logger))
            .through(storeFile(dir.resolve("test.pdf")))
            .compile
            .lastOrError
            .unsafeRunSync()

          assert(Files.exists(p) && Files.size(p) > 0)
        })
        .unsafeRunSync
    }
  }


  def storeFile(file: Path): Pipe[IO, Byte, Path] =
    in => Stream.eval(in.compile.to(Array).flatMap(bytes => IO(Files.write(file, bytes))))

  def commandExists(cmd: String): Boolean =
    Runtime.getRuntime().exec(Array("which", cmd)).waitFor() == 0
}
