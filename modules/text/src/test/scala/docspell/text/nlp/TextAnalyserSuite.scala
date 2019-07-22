package docspell.text.nlp

import docspell.common.{Language, NerLabel, NerTag}
import docspell.text.TestFiles
import minitest.SimpleTestSuite

object TextAnalyserSuite extends SimpleTestSuite {

  test("find english ner labels") {
    val labels = StanfordNerClassifier.nerAnnotate(Language.English)(TestFiles.letterENText)
    val expect = Vector(NerLabel("Derek",NerTag.Person,0,5)
      , NerLabel("Jeter",NerTag.Person,6,11)
      , NerLabel("Treesville",NerTag.Person,27,37)
      , NerLabel("Derek",NerTag.Person,69,74)
      , NerLabel("Jeter",NerTag.Person,75,80)
      , NerLabel("Treesville",NerTag.Location,96,106)
      , NerLabel("M.",NerTag.Person,142,144)
      , NerLabel("Leat",NerTag.Person,145,149)
      , NerLabel("Syrup",NerTag.Organization,160,165)
      , NerLabel("Production",NerTag.Organization,166,176)
      , NerLabel("Old",NerTag.Organization,177,180)
      , NerLabel("Sticky",NerTag.Organization,181,187)
      , NerLabel("Pancake",NerTag.Organization,188,195)
      , NerLabel("Company",NerTag.Organization,196,203)
      , NerLabel("Maple",NerTag.Location,208,213)
      , NerLabel("Lane",NerTag.Location,214,218)
      , NerLabel("Forest",NerTag.Location,220,226)
      , NerLabel("Hemptown",NerTag.Location,241,249)
      , NerLabel("Little",NerTag.Organization,349,355)
      , NerLabel("League",NerTag.Organization,356,362)
      , NerLabel("Derek",NerTag.Person,1119,1124)
      , NerLabel("Jeter",NerTag.Person,1125,1130))
    assertEquals(labels, expect)
  }

  test("find german ner labels") {
    val labels = StanfordNerClassifier.nerAnnotate(Language.German)(TestFiles.letterDEText)
    val expect = Vector(NerLabel("Max", NerTag.Person, 0, 3)
      , NerLabel("Mustermann", NerTag.Person, 4, 14)
      , NerLabel("Lilienweg", NerTag.Location, 16, 25)
      , NerLabel("Max", NerTag.Person, 77, 80)
      , NerLabel("Mustermann", NerTag.Person, 81, 91)
      , NerLabel("Lilienweg", NerTag.Location, 93, 102)
      , NerLabel("EasyCare", NerTag.Organization, 124, 132)
      , NerLabel("AG", NerTag.Organization, 133, 135)
      , NerLabel("Ackerweg", NerTag.Location, 158, 166)
      , NerLabel("Nebendorf", NerTag.Location, 184, 193)
      , NerLabel("Max", NerTag.Person, 505, 508)
      , NerLabel("Mustermann", NerTag.Person, 509, 519))
    assertEquals(labels, expect)
  }
}
