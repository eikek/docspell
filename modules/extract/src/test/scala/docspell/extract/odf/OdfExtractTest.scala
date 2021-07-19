/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.extract.odf

import cats.effect._
import cats.effect.unsafe.implicits.global

import docspell.files.ExampleFiles

import munit._

class OdfExtractTest extends FunSuite {

  val files = List(
    ExampleFiles.examples_sample_odt -> 6367,
    ExampleFiles.examples_sample_ods -> 717
  )

  test("test extract from odt") {
    files.foreach { case (file, len) =>
      val is   = file.toJavaUrl.map(_.openStream()).fold(sys.error, identity)
      val str1 = OdfExtract.get(is).fold(throw _, identity)
      assertEquals(str1.length, len)

      val data = file.readURL[IO](8192)
      val str2 = OdfExtract.get[IO](data).unsafeRunSync().fold(throw _, identity)
      assertEquals(str2, str1)
    }
  }

}
