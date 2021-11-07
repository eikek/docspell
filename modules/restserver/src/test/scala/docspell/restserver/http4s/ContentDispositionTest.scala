/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.http4s

import munit._
import org.http4s.headers.`Content-Disposition`
import org.typelevel.ci._

class ContentDispositionTest extends FunSuite {
  def parseGood(s: String): ContentDisposition = ContentDisposition
    .parse(s)
    .fold(throw _, identity)

  def parseOrig(s: String): ContentDisposition =
    `Content-Disposition`
      .parse(s)
      .map(v => ContentDisposition(v.dispositionType, v.parameters))
      .fold(throw _, identity)

  test("allow rfc2231 parameters with charset") {
    assertEquals(
      parseGood("form-data; name*=us-ascii''This%20is%20%2A%2A%2Afun%2A%2A%2A"),
      ContentDisposition("form-data", Map(ci"name*" -> "This is ***fun***"))
    )
  }

  test("allow rfc2231 parameters with charset and language") {
    assertEquals(
      parseGood("form-data; name*=utf-8'en-us'This%20is%20%2A%2A%2Afun%2A%2A%2A"),
      ContentDisposition("form-data", Map(ci"name*" -> "This is ***fun***"))
    )
  }

  test("allow rfc2231 parameters without charset and language") {
    assertEquals(
      parseGood("form-data; name*=''This%20is%20%2A%2A%2Afun%2A%2A%2A"),
      ContentDisposition("form-data", Map(ci"name*" -> "This is ***fun***"))
    )
  }

  test("allow rfc2231 parameters with quoted strings") {
    assertEquals(
      parseGood("form-data; name*=\"This is ***fun***\""),
      ContentDisposition("form-data", Map(ci"name*" -> "This is ***fun***"))
    )
  }

  test("allow utf8 bytes in filename") {
    assertEquals(
      parseGood("""form-data; name="file"; filename="Константинополя.txt""""),
      ContentDisposition(
        "form-data",
        Map(ci"name" -> "file", ci"filename" -> "Константинополя.txt")
      )
    )
    assertEquals(
      parseGood("""form-data; name=file; filename=Константинополя.txt"""),
      ContentDisposition(
        "form-data",
        Map(ci"name" -> "file", ci"filename" -> "Константинополя.txt")
      )
    )
  }

  // interestingly, this works with the original header impl from http4s. but
  // i've never seen it being used like that in clients
  test("unicode in filename with original header impl and filename*") {
    assertEquals(
      parseOrig("""form-data; name="file"; filename*="Константинополя.txt""""),
      ContentDisposition(
        "form-data",
        Map(ci"name" -> "file", ci"filename*" -> "Константинополя.txt")
      )
    )
  }

  test("allow simple values") {
    assertEquals(
      parseGood("form-data; name=hello"),
      ContentDisposition("form-data", Map(ci"name" -> "hello"))
    )
    assertEquals(
      parseGood("form-data; name=\"hello\""),
      ContentDisposition("form-data", Map(ci"name" -> "hello"))
    )
    assertEquals(
      parseGood("form-data; name=\"hello you\""),
      ContentDisposition("form-data", Map(ci"name" -> "hello you"))
    )
  }
}
