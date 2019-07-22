package docspell.text.date

import docspell.common.Language
import docspell.text.TestFiles
import minitest._

object DateFindSpec extends SimpleTestSuite {

  test("find simple dates") {

    //println(DateFind.findDates(TestFiles.letterDEText, Language.German).toVector)
    println(DateFind.findDates(TestFiles.letterENText, Language.English).toVector)
  }
}
