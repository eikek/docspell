/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import docspell.addons.out.AddonOutput

import io.circe.parser.decode
import munit.FunSuite

class AddonOutputTest extends FunSuite {

  test("decode empty object") {
    val out = decode[AddonOutput]("{}")
    println(out)
  }

  test("decode sample output") {
    val jsonStr =
      """{ "files": [
        |    {
        |      "itemId": "qZDnyGIAJsXr",
        |      "textFiles": {
        |        "HPFvIDib6eA": "HPFvIDib6eA.txt"
        |      },
        |      "pdfFiles": {
        |        "HPFvIDib6eA": "HPFvIDib6eA.pdf"
        |      }
        |    }
        |  ]
        |}
        |""".stripMargin

    val out = decode[AddonOutput](jsonStr)
    println(out)
  }
}
