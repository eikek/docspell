package docspell.analysis.nlp

import minitest.SimpleTestSuite
import docspell.files.TestFiles
import docspell.common._

object TextAnalyserSuite extends SimpleTestSuite {

  test("find english ner labels") {
    val labels = StanfordNerClassifier.nerAnnotate(Language.English)(TestFiles.letterENText)
    val expect = Vector(
      NerLabel("Derek", NerTag.Person, 0, 5),
      NerLabel("Jeter", NerTag.Person, 6, 11),
      NerLabel("Treesville", NerTag.Person, 27, 37),
      NerLabel("Derek", NerTag.Person, 68, 73),
      NerLabel("Jeter", NerTag.Person, 74, 79),
      NerLabel("Treesville", NerTag.Location, 95, 105),
      NerLabel("Syrup", NerTag.Organization, 159, 164),
      NerLabel("Production", NerTag.Organization, 165, 175),
      NerLabel("Old", NerTag.Organization, 176, 179),
      NerLabel("Sticky", NerTag.Organization, 180, 186),
      NerLabel("Pancake", NerTag.Organization, 187, 194),
      NerLabel("Company", NerTag.Organization, 195, 202),
      NerLabel("Maple", NerTag.Location, 207, 212),
      NerLabel("Lane", NerTag.Location, 213, 217),
      NerLabel("Forest", NerTag.Location, 219, 225),
      NerLabel("Hemptown", NerTag.Location, 239, 247),
      NerLabel("Little", NerTag.Organization, 347, 353),
      NerLabel("League", NerTag.Organization, 354, 360),
      NerLabel("Derek", NerTag.Person, 1117, 1122),
      NerLabel("Jeter", NerTag.Person, 1123, 1128)
    )
    assertEquals(labels, expect)
  }

  test("find german ner labels") {
    val labels = StanfordNerClassifier.nerAnnotate(Language.German)(TestFiles.letterDEText)
    val expect = Vector(
      NerLabel("Max", NerTag.Person, 0, 3),
      NerLabel("Mustermann", NerTag.Person, 4, 14),
      NerLabel("Lilienweg", NerTag.Location, 16, 25),
      NerLabel("Max", NerTag.Person, 77, 80),
      NerLabel("Mustermann", NerTag.Person, 81, 91),
      NerLabel("Lilienweg", NerTag.Location, 93, 102),
      NerLabel("EasyCare", NerTag.Organization, 124, 132),
      NerLabel("AG", NerTag.Organization, 133, 135),
      NerLabel("Ackerweg", NerTag.Location, 158, 166),
      NerLabel("Nebendorf", NerTag.Location, 184, 193),
      NerLabel("Max", NerTag.Person, 505, 508),
      NerLabel("Mustermann", NerTag.Person, 509, 519)
    )
    assertEquals(labels, expect)
  }
}
