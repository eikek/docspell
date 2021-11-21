/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.jsonminiq

import cats.parse.{Parser => P}

import io.circe.Json

trait Fixtures {

  val sampleEvent: Json =
    parseJson(
      """{
        |  "eventType": "TagsChanged",
        |  "account": {
        |    "collective": "demo",
        |    "user": "demo",
        |    "login": "demo"
        |  },
        |  "content": {
        |    "account": "demo",
        |    "items": [
        |      {
        |        "id": "4PvMM4m7Fwj-FsPRGxYt9zZ-uUzi35S2rEX-usyDEVyheR8",
        |        "name": "MapleSirupLtd_202331.pdf",
        |        "dateMillis": 1633557740733,
        |        "date": "2021-10-06",
        |        "direction": "incoming",
        |        "state": "confirmed",
        |        "dueDateMillis": 1639173740733,
        |        "dueDate": "2021-12-10",
        |        "source": "webapp",
        |        "overDue": false,
        |        "dueIn": "in 3 days",
        |        "corrOrg": "Acme AG",
        |        "notes": null
        |      }
        |    ],
        |    "added": [
        |      {
        |        "id": "Fy4VC6hQwcL-oynrHaJg47D-Q5RiQyB5PQP-N5cFJ368c4N",
        |        "name": "Invoice",
        |        "category": "doctype"
        |      },
        |      {
        |        "id": "7zaeU6pqVym-6Je3Q36XNG2-ZdBTFSVwNjc-pJRXciTMP3B",
        |        "name": "Grocery",
        |        "category": "expense"
        |      }      
        |    ],
        |    "removed": [
        |      {
        |        "id": "GbXgszdjBt4-zrzuLHoUx7N-RMFatC8CyWt-5dsBCvxaEuW",
        |        "name": "Receipt",
        |        "category": "doctype"
        |      }
        |    ],
        |    "itemUrl": "http://localhost:7880/app/item"
        |  }
        |}""".stripMargin
    )

  def parseJson(str: String): Json =
    io.circe.parser.parse(str).fold(throw _, identity)

  def parseP[A](p: P[A], str: String): A =
    p.parseAll(str.trim())
      .fold(e => sys.error(s"${e.getClass}: $e"), identity)

  def parse(str: String): JsonMiniQuery = parseP(Parser.query, str)

}
