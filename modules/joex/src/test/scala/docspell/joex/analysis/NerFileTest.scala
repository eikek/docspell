package docspell.joex.analysis

import munit._
import NerFile.Pattern
import java.{util => ju}

class NerFileTest extends FunSuite {

  test("create valid case insensitive patterns") {
    val names = List(
      "Some company AG"            -> "(?i)some company ag",
      "Acme GmbH"                  -> "(?i)acme gmbh",
      "UP"                         -> "(?i)up",
      "1 & 1"                      -> "(?i)1 & 1",
      "1 & 1 (Telefon / Internet)" -> "(?i)1 & 1 \\(telefon / internet\\)",
      "X-corp (this)*-*[one]"      -> "(?i)x\\-corp \\(this\\)\\*\\-\\*\\[one\\]"
    )

    for ((name, first) <- names) {
      val ps = Pattern(1)(name).distinct
      //check if it compiles to a regex pattern
      ps.flatMap(_.value.split("\\s+").toList).foreach(_.r)
      ps.foreach(_.value.r)

      val regex = ps.head.value.r
      regex.matches(name)
      regex.matches(name.toLowerCase(ju.Locale.ROOT))
      regex.matches(name.toUpperCase(ju.Locale.ROOT))

      assertEquals(ps.head.value, first)
    }
  }
}
