package docspell.query.internal

import minitest._
import docspell.query.Date

object DateParserTest extends SimpleTestSuite {

  def ld(year: Int, m: Int, d: Int): Date =
    Date(year, m, d)

  test("local date string") {
    val p = DateParser.localDateFromString
    assertEquals(p.parseAll("2021-02-22"), Right(ld(2021, 2, 22)))
    assertEquals(p.parseAll("1999-11-11"), Right(ld(1999, 11, 11)))
    assertEquals(p.parseAll("2032-01-21"), Right(ld(2032, 1, 21)))
    assert(p.parseAll("0-0-0").isLeft)
    assert(p.parseAll("2021-02-30").isRight)
  }

  test("local date millis") {
    val p = DateParser.dateFromMillis
    assertEquals(p.parseAll("0"), Right(Date(0)))
    assertEquals(
      p.parseAll("1600000065463"),
      Right(Date(1600000065463L))
    )
  }

  test("local date") {
    val p = DateParser.localDate
    assertEquals(p.parseAll("2021-02-22"), Right(ld(2021, 2, 22)))
    assertEquals(p.parseAll("1999-11-11"), Right(ld(1999, 11, 11)))
    assertEquals(p.parseAll("0"), Right(Date(0)))
    assertEquals(p.parseAll("1600000065463"), Right(Date(1600000065463L)))
  }
}
