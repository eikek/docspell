package docspell.extract.ocr

import cats.effect.IO
import docspell.common._
import docspell.files._
import docspell.extract.TestFiles
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

  test("find mimetypes") {
    ExampleFiles.
      all.foreach { url =>
        TikaMimetype.detect(url.readURL[IO](8192, blocker), MimeTypeHint.none).
          map(mt => println(url.asString + ": " + mt.asString)).
          unsafeRunSync
      }
  }
}
