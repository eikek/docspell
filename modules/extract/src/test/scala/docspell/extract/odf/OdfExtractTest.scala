package docspell.extract.odf

import cats.effect._
import docspell.files.{ExampleFiles, TestFiles}
import minitest.SimpleTestSuite

object OdfExtractTest extends SimpleTestSuite {
  val blocker = TestFiles.blocker
  implicit val CS = TestFiles.CS

  val files = List(
    ExampleFiles.examples_sample_odt -> 6372,
    ExampleFiles.examples_sample_ods -> 717
  )

  test("test extract from odt") {
    files.foreach { case (file, len) =>
      val is = file.toJavaUrl.map(_.openStream()).fold(sys.error, identity)
      val str1 = OdfExtract.get(is).fold(throw _, identity)
      assertEquals(str1.length, len)

      val data = file.readURL[IO](8192, blocker)
      val str2 = OdfExtract.get[IO](data).unsafeRunSync().fold(throw _, identity)
      assertEquals(str2, str1)
    }
  }

}
