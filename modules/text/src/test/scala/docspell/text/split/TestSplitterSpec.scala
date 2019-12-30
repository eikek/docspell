package docspell.text.split

import minitest._

object TestSplitterSpec extends SimpleTestSuite {

  test("simple splitting") {
    val text = """hiermit kündige ich meine Mitgliedschaft in der Kranken- und
                 |Pflegeversicherung zum nächstmöglichen Termin.
                 |
                 |Bitte senden Sie mir innerhalb der gesetzlichen Frist von 14 Tagen
                 |eine Kündigungsbestätigung zu.
                 |
                 |Vielen Dank im Vorraus!""".stripMargin

    val words = TextSplitter.splitToken(text, " \t\r\n".toSet).toVector

    assertEquals(words.size, 31)
    assertEquals(words(13), Word("bitte", 109, 114))
    assertEquals(text.substring(109, 114).toLowerCase, "bitte")
  }

}
