package docspell.extract.ocr

import cats.effect.IO
import docspell.common.Logger
import docspell.files.TestFiles
import munit._

class TextExtractionSuite extends FunSuite {
  import TestFiles._

  val logger = Logger.log4s[IO](org.log4s.getLogger)

  test("extract english pdf".ignore) {
    val text = TextExtract
      .extract[IO](letterSourceEN, blocker, logger, "eng", OcrConfig.default)
      .compile
      .lastOrError
      .unsafeRunSync()
    println(text)
  }

  test("extract german pdf".ignore) {
    val expect = TestFiles.letterDEText
    val extract = TextExtract
      .extract[IO](letterSourceDE, blocker, logger, "deu", OcrConfig.default)
      .compile
      .lastOrError
      .unsafeRunSync()

    assertEquals(extract.value, expect)
  }
}
