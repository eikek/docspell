/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.pdfbox

import docspell.logging.TestLoggingConfig

import munit._

class PdfMetaDataTest extends FunSuite with TestLoggingConfig {

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
