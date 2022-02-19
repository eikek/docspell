/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.ocr

import cats.effect.IO
import cats.effect.unsafe.implicits.global

import docspell.files.TestFiles

import munit._

class TextExtractionSuite extends FunSuite {
  import TestFiles._

  val logger = docspell.logging.getLogger[IO]

  test("extract english pdf".ignore) {
    val text = TextExtract
      .extract[IO](letterSourceEN, logger, "eng", OcrConfig.default)
      .compile
      .lastOrError
      .unsafeRunSync()
    println(text)
  }

  test("extract german pdf".ignore) {
    val expect = TestFiles.letterDEText
    val extract = TextExtract
      .extract[IO](letterSourceDE, logger, "deu", OcrConfig.default)
      .compile
      .lastOrError
      .unsafeRunSync()

    assertEquals(extract.value, expect)
  }
}
