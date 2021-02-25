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
        NerLabel("November 7, 2016", NerTag.Date, 50, 66)
      ),
      NerDateLabel(
        LocalDate.parse("2016-11-07"),
        NerLabel("November 7, 2016", NerTag.Date, 119, 135)
      ),
      NerDateLabel(
        LocalDate.parse("2019-09-03"),
        NerLabel("September 3, 2019", NerTag.Date, 249, 266)
      ),
      NerDateLabel(
        LocalDate.parse("2016-12-12"),
        NerLabel("December 12, 2016", NerTag.Date, 1076, 1093)
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

  test("different date formats") {
    assertEquals(
      DateFind.findDates("on 11/05/2020", Language.English).toVector,
      Vector(
        NerDateLabel(
          LocalDate.of(2020, 5, 11),
          NerLabel("11/05/2020", NerTag.Date, 3, 13)
        ),
        NerDateLabel(
          LocalDate.of(2020, 11, 5),
          NerLabel("11/05/2020", NerTag.Date, 3, 13)
        )
      )
    )
    assertEquals(
      DateFind.findDates("on 21/05/2020", Language.English).toVector,
      Vector(
        NerDateLabel(
          LocalDate.of(2020, 5, 21),
          NerLabel("21/05/2020", NerTag.Date, 3, 13)
        )
      )
    )
  }

  test("more english variants") {
    assertEquals(
      DateFind.findDates("on 26/01/15", Language.English).toVector,
      Vector(
        NerDateLabel(
          LocalDate.of(2015, 1, 26),
          NerLabel("26/01/15", NerTag.Date, 3, 11)
        ),
        NerDateLabel(
          LocalDate.of(2026, 1, 15),
          NerLabel("26/01/15", NerTag.Date, 3, 11)
        )
      )
    )

    assertEquals(
      DateFind.findDates("on 10/09/11", Language.English).toVector,
      Vector(
        NerDateLabel(
          LocalDate.of(2011, 9, 10),
          NerLabel("10/09/11", NerTag.Date, 3, 11)
        ),
        NerDateLabel(
          LocalDate.of(2011, 10, 9),
          NerLabel("10/09/11", NerTag.Date, 3, 11)
        ),
        NerDateLabel(
          LocalDate.of(2010, 9, 11),
          NerLabel("10/09/11", NerTag.Date, 3, 11)
        )
      )
    )
  }

}
