/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.files

import docspell.common.{MimeType, MimeTypeHint}

import munit.FunSuite
import scodec.bits.ByteVector

class TikaMimetypeTest extends FunSuite {

  private def detect(bv: ByteVector, hint: MimeTypeHint): MimeType =
    TikaMimetype.detect(bv, hint)

  test("detect text/plain") {
    val mt = detect(ByteVector.view("hello world".getBytes), MimeTypeHint.none)
    assertEquals(mt.baseType, MimeType.plain)
  }

  test("detect image/jpeg") {
    val mt = detect(
      ByteVector.fromValidBase64("/9j/4AAQSkZJRgABAgAAZABkAAA="),
      MimeTypeHint.none
    )
    assertEquals(mt, MimeType.jpeg)
  }

  test("detect image/png") {
    val mt = detect(
      ByteVector.fromValidBase64("iVBORw0KGgoAAAANSUhEUgAAA2I="),
      MimeTypeHint.none
    )
    assertEquals(mt, MimeType.png)
  }

  test("detect application/json") {
    val mt =
      detect(
        ByteVector.view("""{"name":"me"}""".getBytes),
        MimeTypeHint.filename("me.json")
      )
    assertEquals(mt, MimeType.json)
  }

  test("detect application/json") {
    val mt = detect(
      ByteVector.view("""{"name":"me"}""".getBytes),
      MimeTypeHint.advertised("application/json")
    )
    assertEquals(mt, MimeType.json)
  }

  test("detect image/jpeg wrong advertised") {
    val mt = detect(
      ByteVector.fromValidBase64("/9j/4AAQSkZJRgABAgAAZABkAAA="),
      MimeTypeHint.advertised("image/png")
    )
    assertEquals(mt, MimeType.jpeg)
  }

  test("just filename") {
    assertEquals(
      detect(ByteVector.empty, MimeTypeHint.filename("doc.pdf")),
      MimeType.pdf
    )
  }

}
