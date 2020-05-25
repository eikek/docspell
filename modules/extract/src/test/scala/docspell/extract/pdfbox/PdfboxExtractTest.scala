package docspell.extract.pdfbox

import cats.effect._
import docspell.files.{ExampleFiles, TestFiles}
import minitest.SimpleTestSuite

object PdfboxExtractTest extends SimpleTestSuite {
  val blocker     = TestFiles.blocker
  implicit val CS = TestFiles.CS

  val textPDFs = List(
    ExampleFiles.letter_de_pdf -> TestFiles.letterDEText,
    ExampleFiles.letter_en_pdf -> TestFiles.letterENText
  )

  test("extract text from text PDFs by inputstream") {
    textPDFs.foreach {
      case (file, txt) =>
        val url      = file.toJavaUrl.fold(sys.error, identity)
        val str      = PdfboxExtract.get(url.openStream()).fold(throw _, identity)
        val received = removeFormatting(str.value)
        val expect   = removeFormatting(txt)
        assertEquals(received, expect)
    }
  }

  test("extract text from text PDFs via Stream") {
    textPDFs.foreach {
      case (file, txt) =>
        val data     = file.readURL[IO](8192, blocker)
        val str      = PdfboxExtract.get(data).unsafeRunSync().fold(throw _, identity)
        val received = removeFormatting(str.value)
        val expect   = removeFormatting(txt)
        assertEquals(received, expect)
    }
  }

  test("extract text from image PDFs") {
    val url = ExampleFiles.scanner_pdf13_pdf.toJavaUrl.fold(sys.error, identity)

    val str = PdfboxExtract.get(url.openStream()).fold(throw _, identity)

    assertEquals(str.value, "")
  }

  private def removeFormatting(str: String): String =
    str.replaceAll("[\\s;:.,\\-]+", "").toLowerCase
}
