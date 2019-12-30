package docspell.text.ocr

import cats.effect.IO
import docspell.text.TestFiles
import minitest.SimpleTestSuite

object TextExtractionSuite extends SimpleTestSuite {
  import TestFiles._

  test("extract english pdf") {
    ignore()
    val text = TextExtract
      .extract[IO](letterSourceEN, blocker, "eng", Config.default)
      .compile
      .lastOrError
      .unsafeRunSync()
    println(text)
  }

  test("extract german pdf") {
    ignore()
    val expect = TestFiles.letterDEText
    val extract = TextExtract
      .extract[IO](letterSourceDE, blocker, "deu", Config.default)
      .compile
      .lastOrError
      .unsafeRunSync()

    assertEquals(extract.trim, expect.trim)
  }
}
