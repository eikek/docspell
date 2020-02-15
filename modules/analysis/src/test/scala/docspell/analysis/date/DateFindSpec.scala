package docspell.analysis.date

import docspell.analysis.TestFiles
import minitest.SimpleTestSuite
import docspell.common.Language

object DateFindSpec extends SimpleTestSuite {

  test("find simple dates") {

    //println(DateFind.findDates(TestFiles.letterDEText, Language.German).toVector)
    println(DateFind.findDates(TestFiles.letterENText, Language.English).toVector)
  }
}
