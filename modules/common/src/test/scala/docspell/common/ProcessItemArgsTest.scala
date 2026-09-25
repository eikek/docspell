/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe.syntax._
import munit.FunSuite

class ProcessItemArgsTest extends FunSuite {

  private def meta(
      process: Option[Boolean],
      runAddons: Option[Boolean] = None
  ): ProcessItemArgs.ProcessMeta =
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
      process = process,
      runAddons = runAddons
    )

  test("isProcessingEnabled defaults to true") {
    val args = ProcessItemArgs(meta(None), Nil)
    assert(args.isProcessingEnabled)
  }

  test("isProcessingEnabled respects process=false") {
    val args = ProcessItemArgs(meta(Some(false)), Nil)
    assert(!args.isProcessingEnabled)
  }

  test("isRunAddonsEnabled defaults to true") {
    val args = ProcessItemArgs(meta(Some(false)), Nil)
    assert(args.isRunAddonsEnabled)
  }

  test("isRunAddonsEnabled respects runAddons=false") {
    val args = ProcessItemArgs(meta(Some(false), Some(false)), Nil)
    assert(!args.isRunAddonsEnabled)
  }

  test("decode ProcessMeta without process/runAddons fields") {
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
    assertEquals(decoded.runAddons, None)
    assert(ProcessItemArgs(decoded, Nil).isProcessingEnabled)
    assert(ProcessItemArgs(decoded, Nil).isRunAddonsEnabled)
  }

  test("roundtrip process=false and runAddons=false") {
    val m = meta(Some(false), Some(false))
    assertEquals(m.asJson.as[ProcessItemArgs.ProcessMeta], Right(m))
  }
}
