/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.syntax._
import munit.FunSuite

class ProcessItemArgsTest extends FunSuite {

  private def meta(process: Option[Boolean]): ProcessItemArgs.ProcessMeta =
    ProcessItemArgs.ProcessMeta(
      collective = CollectiveId(1),
      itemId = None,
      language = Language.English,
      direction = None,
      sourceAbbrev = "webapp",
      folderId = None,
      validFileTypes = Seq.empty,
      skipDuplicate = false,
      fileFilter = None,
      tags = None,
      reprocess = false,
      attachmentsOnly = None,
      customData = None,
      process = process
    )

  test("isProcessingEnabled defaults to true") {
    val args = ProcessItemArgs(meta(None), Nil)
    assert(args.isProcessingEnabled)
  }

  test("isProcessingEnabled respects process=false") {
    val args = ProcessItemArgs(meta(Some(false)), Nil)
    assert(!args.isProcessingEnabled)
  }

  test("decode ProcessMeta without process field") {
    val json =
      """{
        |  "collective": 1,
        |  "itemId": null,
        |  "language": "eng",
        |  "direction": null,
        |  "sourceAbbrev": "webapp",
        |  "folderId": null,
        |  "validFileTypes": [],
        |  "skipDuplicate": false,
        |  "fileFilter": null,
        |  "tags": null,
        |  "reprocess": false,
        |  "attachmentsOnly": null,
        |  "customData": null
        |}""".stripMargin

    val decoded = io.circe.parser.decode[ProcessItemArgs.ProcessMeta](json).toOption.get
    assertEquals(decoded.process, None)
    assert(ProcessItemArgs(decoded, Nil).isProcessingEnabled)
  }

  test("roundtrip process=false") {
    val m = meta(Some(false))
    assertEquals(m.asJson.as[ProcessItemArgs.ProcessMeta], Right(m))
  }
}
