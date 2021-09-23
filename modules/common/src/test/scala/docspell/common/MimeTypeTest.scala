/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.nio.charset.{Charset, StandardCharsets}

import scala.jdk.CollectionConverters._

import munit.ScalaCheckSuite
import org.scalacheck.Gen
import org.scalacheck.Prop.forAll

class MimeTypeTest extends ScalaCheckSuite {

  test("asString") {
    assertEquals(MimeType.html.asString, "text/html")
    assertEquals(
      MimeType.html.withCharset(StandardCharsets.ISO_8859_1).asString,
      "text/html; charset=\"ISO-8859-1\""
    )
    assertEquals(
      MimeType.html.withUtf8Charset.asString,
      "text/html; charset=\"UTF-8\""
    )
  }

  test("parse without params") {
    assertEquals(MimeType.unsafe("application/pdf"), MimeType.pdf)
    assertEquals(MimeType.unsafe("image/jpeg"), MimeType.jpeg)

    assertEquals(MimeType.unsafe("image/jpeg "), MimeType.jpeg)
    assertEquals(MimeType.unsafe("  image/jpeg "), MimeType.jpeg)
    assertEquals(MimeType.unsafe("  image / jpeg "), MimeType.jpeg)

    assertEquals(
      MimeType.unsafe("application/xml+html"),
      MimeType.application("xml+html")
    )
    assertEquals(
      MimeType.unsafe(
        "application/vnd.openxmlformats-officedocument.presentationml.viewProps+xml"
      ),
      MimeType.application(
        "vnd.openxmlformats-officedocument.presentationml.viewprops+xml"
      )
    )
    assertEquals(
      MimeType.unsafe("application/vnd.powerbuilder75-s"),
      MimeType.application("vnd.powerbuilder75-s")
    )
  }

  test("parse with charset") {
    assertEquals(
      MimeType.unsafe("text/plain; charset=UTF-8"),
      MimeType.plain.withUtf8Charset
    )
    assertEquals(
      MimeType.unsafe("text/plain; CHARSET=UTF-8"),
      MimeType.plain.withUtf8Charset
    )
    assertEquals(
      MimeType.unsafe("text/plain; CharSet=UTF-8"),
      MimeType.plain.withUtf8Charset
    )
    assertEquals(
      MimeType.unsafe("text/html; charset=\"ISO-8859-1\""),
      MimeType.html.withCharset(StandardCharsets.ISO_8859_1)
    )
  }

  test("parse with charset and more params") {
    assertEquals(
      MimeType.unsafe("text/plain; charset=UTF-8; action=test"),
      MimeType.plain.withUtf8Charset
    )
    assertEquals(
      MimeType.unsafe("text/plain; run=\"2\"; charset=UTF-8; action=test"),
      MimeType.plain.withUtf8Charset
    )
  }

  test("parse without charset but params") {
    assertEquals(MimeType.unsafe("image/jpeg; action=urn:2"), MimeType.jpeg)
  }

  test("parse some stranger values") {
    assertEquals(
      MimeType.unsafe("text/plain; charset=\"\"ISO-8859-1\"\""),
      MimeType.plain.withCharset(StandardCharsets.ISO_8859_1)
    )
    assertEquals(
      MimeType.unsafe("text/plain; charset=\"\" ISO-8859-1 \"\""),
      MimeType.plain.withCharset(StandardCharsets.ISO_8859_1)
    )
  }

  test("parse invalid mime types") {
    assert(MimeType.parse("").isLeft)
    assert(MimeType.parse("_ _/plain").isLeft)
    assert(MimeType.parse("/").isLeft)
    assert(MimeType.parse("()").isLeft)
  }

  property("read own asString") {
    forAll(MimeTypeTest.mimeType) { mt: MimeType =>
      assertEquals(MimeType.unsafe(mt.asString), mt)
    }
  }
}

object MimeTypeTest {
  val someTypes = List(
    MimeType.plain,
    MimeType.html
  ) ++ MimeType.emls.toList

  val mimeType =
    for {
      base <- Gen.atLeastOne(someTypes)
      cs <- Gen.someOf(Charset.availableCharsets().values().asScala)
    } yield base.head.copy(charset = cs.headOption)

}
