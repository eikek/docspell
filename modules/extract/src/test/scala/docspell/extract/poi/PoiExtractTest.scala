package docspell.extract.poi

import cats.effect._
import docspell.common.MimeTypeHint
import docspell.files.{ExampleFiles, TestFiles}
import minitest.SimpleTestSuite

object PoiExtractTest extends SimpleTestSuite {
  val blocker     = TestFiles.blocker
  implicit val CS = TestFiles.CS

  val officeFiles = List(
    ExampleFiles.examples_sample_doc  -> 6241,
    ExampleFiles.examples_sample_docx -> 6179,
    ExampleFiles.examples_sample_xlsx -> 660,
    ExampleFiles.examples_sample_xls  -> 660
  )

  test("extract text from ms office files") {
    officeFiles.foreach { case (file, len) =>
      val str1 = PoiExtract
        .get[IO](file.readURL[IO](8192, blocker), MimeTypeHint.none)
        .unsafeRunSync()
        .fold(throw _, identity)

      val str2 = PoiExtract
        .get[IO](
          file.readURL[IO](8192, blocker),
          MimeTypeHint(Some(file.path.segments.last), None)
        )
        .unsafeRunSync()
        .fold(throw _, identity)

      assertEquals(str1, str2)
      assertEquals(str1.length, len)
    }
  }
}
