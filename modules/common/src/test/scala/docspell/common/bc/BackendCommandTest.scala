/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.bc

import docspell.common._

import io.circe.parser
import io.circe.syntax._
import munit._

class BackendCommandTest extends FunSuite {

  test("encode json") {
    val bc: BackendCommand =
      BackendCommand.item(
        id("abc"),
        List(
          ItemAction.RemoveTagsCategory(Set("doctype")),
          ItemAction.AddTags(Set("tag1", "tag2"))
        )
      )

    assertEquals(
      bc.asJson.spaces2,
      """{
        |  "itemId" : "abc",
        |  "actions" : [
        |    {
        |      "categories" : [
        |        "doctype"
        |      ],
        |      "action" : "remove-tags-category"
        |    },
        |    {
        |      "tags" : [
        |        "tag1",
        |        "tag2"
        |      ],
        |      "action" : "add-tags"
        |    }
        |  ],
        |  "command" : "item-update"
        |}""".stripMargin
    )
  }

  test("decode case insensitive keys") {
    val json = """{
                 |  "itemId" : "abc",
                 |  "actions" : [
                 |    {
                 |      "categories" : [
                 |        "doctype"
                 |      ],
                 |      "action" : "remove-tags-category"
                 |    },
                 |    {
                 |      "tags" : [
                 |        "tag1",
                 |        "tag2"
                 |      ],
                 |      "action" : "add-tags"
                 |    }
                 |  ],
                 |  "command" : "item-update"
                 |}""".stripMargin

    val bc: BackendCommand =
      BackendCommand.item(
        id("abc"),
        List(
          ItemAction.RemoveTagsCategory(Set("doctype")),
          ItemAction.AddTags(Set("tag1", "tag2"))
        )
      )

    assertEquals(parser.decode[BackendCommand](json), Right(bc))
  }

  def id(str: String) = Ident.unsafe(str)
}
