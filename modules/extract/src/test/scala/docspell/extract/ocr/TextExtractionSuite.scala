package docspell.extract.ocr

import cats.effect.IO
import docspell.files.TestFiles
import minitest.SimpleTestSuite

object TextExtractionSuite extends SimpleTestSuite {
  import TestFiles._

  test("extract english pdf") {
    ignore()
    val text = TextExtract
      .extract[IO](letterSourceEN, blocker, "eng", OcrConfig.default)
      .compile
      .lastOrError
      .unsafeRunSync()
    println(text)
  }

  test("extract german pdf") {
    ignore()
    val expect = TestFiles.letterDEText
    val extract = TextExtract
      .extract[IO](letterSourceDE, blocker, "deu", OcrConfig.default)
      .compile
      .lastOrError
      .unsafeRunSync()

    assertEquals(extract.trim, expect.trim)
  }
}
