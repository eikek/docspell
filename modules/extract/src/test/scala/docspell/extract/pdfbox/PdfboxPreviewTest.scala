package docspell.extract.pdfbox

import cats.effect._
import docspell.files.{ExampleFiles, TestFiles}
import minitest.SimpleTestSuite
import java.nio.file.Path
import fs2.Stream

object PdfboxPreviewTest extends SimpleTestSuite {
  val blocker     = TestFiles.blocker
  implicit val CS = TestFiles.CS

  val testPDFs = List(
    ExampleFiles.letter_de_pdf     -> "83bdb379fe9ce86e830adfbe11238808bed9da6e31c1b66687d70b6b59a0d815",
    ExampleFiles.letter_en_pdf     -> "699655a162c0c21dd9f19d8638f4e03811c6626a52bb30a1ac733d7fa5638932",
    ExampleFiles.scanner_pdf13_pdf -> "a1680b80b42d8e04365ffd1e806ea2a8adb0492104cc41d8b40435b0fe4d4e65"
  )

  test("extract first page image from PDFs") {
    testPDFs.foreach { case (file, checksum) =>
      val data = file.readURL[IO](8192, blocker)
      val sha256out =
        Stream
          .eval(PdfboxPreview[IO](PreviewConfig(48)))
          .evalMap(_.previewPNG(data))
          .flatMap(_.get)
          .through(fs2.hash.sha256)
          .chunks
          .map(_.toByteVector)
          .fold1(_ ++ _)
          .compile
          .lastOrError
          .map(_.toHex.toLowerCase)

      assertEquals(sha256out.unsafeRunSync(), checksum)
    }
  }

  def writeToFile(data: Stream[IO, Byte], file: Path): IO[Unit] =
    data
      .through(
        fs2.io.file.writeAll(file, blocker)
      )
      .compile
      .drain
}
