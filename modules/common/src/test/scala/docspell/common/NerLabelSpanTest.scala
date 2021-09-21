/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import munit._

class NerLabelSpanTest extends FunSuite {

  test("build") {
    val labels = List(
      NerLabel("Derek", NerTag.Person, 0, 5),
      NerLabel("Jeter", NerTag.Person, 6, 11),
      NerLabel("Treesville", NerTag.Person, 27, 37),
      NerLabel("Derek", NerTag.Person, 68, 73),
      NerLabel("Jeter", NerTag.Person, 74, 79),
      NerLabel("Treesville", NerTag.Location, 95, 105),
      NerLabel("Syrup", NerTag.Organization, 162, 167),
      NerLabel("Production", NerTag.Organization, 168, 178),
      NerLabel("Old", NerTag.Organization, 179, 182),
      NerLabel("Sticky", NerTag.Organization, 183, 189),
      NerLabel("Pancake", NerTag.Organization, 190, 197),
      NerLabel("Company", NerTag.Organization, 198, 205),
      NerLabel("Maple", NerTag.Location, 210, 215),
      NerLabel("Lane", NerTag.Location, 216, 220),
      NerLabel("Forest", NerTag.Location, 222, 238),
      NerLabel("Hemptown", NerTag.Location, 243, 251),
      NerLabel("Little", NerTag.Organization, 351, 357),
      NerLabel("League", NerTag.Organization, 358, 364),
      NerLabel("Derek", NerTag.Person, 1121, 1126),
      NerLabel("Jeter", NerTag.Person, 1127, 1132),
      NerLabel("2016-11-07", NerTag.Date, 50, 60),
      NerLabel("2016-11-07", NerTag.Date, 119, 129),
      NerLabel("2019-09-03", NerTag.Date, 253, 264),
      NerLabel("2016-12-12", NerTag.Date, 1080, 1091)
    )

    val spans = NerLabelSpan.build(labels)
    assertEquals(
      spans,
      Vector(
        NerLabel("Derek Jeter", NerTag.Person, 0, 11),
        NerLabel("Derek Jeter", NerTag.Person, 68, 79),
        NerLabel(
          "Syrup Production Old Sticky Pancake Company",
          NerTag.Organization,
          162,
          205
        ),
        NerLabel("Maple Lane", NerTag.Location, 210, 220),
        NerLabel("Little League", NerTag.Organization, 351, 364),
        NerLabel("Derek Jeter", NerTag.Person, 1121, 1132)
      )
    )
  }
}
