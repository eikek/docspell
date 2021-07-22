/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.extract.pdfbox

import munit._

class PdfMetaDataTest extends FunSuite {

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
