package docspell.analysis.date

import docspell.files.TestFiles
import minitest.SimpleTestSuite
import docspell.common._
import java.time._

object DateFindSpec extends SimpleTestSuite {

  test("find simple dates") {
    val expect = Vector(
      NerDateLabel(
        LocalDate.parse("2016-11-07"),
        NerLabel("November 7, 2016", NerTag.Date, 50, 60)
      ),
      NerDateLabel(
        LocalDate.parse("2016-11-07"),
        NerLabel("November 7, 2016", NerTag.Date, 119, 129)
      ),
      NerDateLabel(
        LocalDate.parse("2019-09-03"),
        NerLabel("September 3, 2019", NerTag.Date, 249, 260)
      ),
      NerDateLabel(
        LocalDate.parse("2016-12-12"),
        NerLabel("December 12, 2016", NerTag.Date, 1076, 1087)
      )
    )

    assertEquals(
      DateFind.findDates(TestFiles.letterENText, Language.English).toVector,
      expect
    )
  }

  test("skip invalid dates") {
    assertEquals(
      DateFind.findDates("Feb 29, 2005", Language.English).toVector,
      Vector.empty
    )
    assertEquals(
      DateFind.findDates("30. Februar 1990", Language.German).toVector,
      Vector.empty
    )
  }
}
