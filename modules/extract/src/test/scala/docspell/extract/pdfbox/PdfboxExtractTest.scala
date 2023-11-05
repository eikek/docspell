/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.pdfbox

import cats.effect._
import cats.effect.unsafe.implicits.global

import docspell.files.{ExampleFiles, TestFiles}
import docspell.logging.TestLoggingConfig

import munit._

class PdfboxExtractTest extends FunSuite with TestLoggingConfig {

  val textPDFs = List(
    ExampleFiles.letter_de_pdf -> TestFiles.letterDEText,
    ExampleFiles.letter_en_pdf -> TestFiles.letterENText
  )

  test("extract text from text PDFs via Stream") {
    textPDFs.foreach { case (file, txt) =>
      val data = file.readURL[IO](8192)
      val str = PdfboxExtract.getText(data).unsafeRunSync().fold(throw _, identity)
      val received = removeFormatting(str.value)
      val expect = removeFormatting(txt)
      assertEquals(received, expect)
    }
  }

  test("extract text from image PDFs") {
    val pdfData = ExampleFiles.scanner_pdf13_pdf.readURL[IO](8192)

    val str = PdfboxExtract.getText(pdfData).unsafeRunSync().fold(throw _, identity)

    assertEquals(str.value, "")
  }

  test("extract metadata from pdf") {
    val pdfData = ExampleFiles.keywords_pdf.readURL[IO](8192)
    val str = PdfboxExtract.getText(pdfData).unsafeRunSync().fold(throw _, identity)
    assert(str.value.startsWith("Keywords in PDF"))
    val md = PdfboxExtract.getMetaData(pdfData).unsafeRunSync().fold(throw _, identity)
    assertEquals(md.author, Some("E.K."))
    assertEquals(md.title, Some("Keywords in PDF"))
    assertEquals(md.subject, Some("This is a subject"))
    assertEquals(md.keywordList, List("Test", "Keywords in PDF", "Todo"))
    assertEquals(md.creator, Some("Emacs 26.3 (Org mode 9.3)"))
    assert(md.creationDate.isDefined)
  }

  private def removeFormatting(str: String): String =
    str.replaceAll("[\\s;:.,\\-]+", "").toLowerCase
}
