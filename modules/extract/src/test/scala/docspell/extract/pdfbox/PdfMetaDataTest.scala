package docspell.extract.pdfbox

import minitest.SimpleTestSuite

object PdfMetaDataTest extends SimpleTestSuite {

  test("split keywords on comma") {
    val md = PdfMetaData.empty.copy(keywords = Some("a,b, c"))
    assertEquals(md.keywordList, List("a", "b", "c"))
  }

  test("split keywords on semicolon") {
    val md = PdfMetaData.empty.copy(keywords = Some("a; b;c"))
    assertEquals(md.keywordList, List("a", "b", "c"))
  }

  test("split keywords on comma and semicolon") {
    val md = PdfMetaData.empty.copy(keywords = Some("a, b; c"))
    assertEquals(md.keywordList, List("a", "b", "c"))
  }

}
