package docspell.joex.scheduler

import docspell.common.Priority
import munit._

class CountingSchemeSpec extends FunSuite {

  test("counting") {
    val cs     = CountingScheme(2, 1)
    val list   = List.iterate(cs.nextPriority, 6)(_._1.nextPriority).map(_._2)
    val expect = List(Priority.High, Priority.High, Priority.Low)
    assertEquals(list, expect ++ expect)
  }

}
