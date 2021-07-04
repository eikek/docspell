/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.files

import scala.util.Using

import cats.effect._
import cats.effect.unsafe.implicits.global
import cats.implicits._

import munit._

class ImageSizeTest extends FunSuite {

  //tiff files are not supported on the jdk by default
  //requires an external library
  val files = List(
    ExampleFiles.camera_letter_en_jpg -> Dimension(1695, 2378),
    ExampleFiles.camera_letter_en_png -> Dimension(1695, 2378),
//    ExampleFiles.camera_letter_en_tiff -> Dimension(1695, 2378),
    ExampleFiles.scanner_jfif_jpg    -> Dimension(2480, 3514),
    ExampleFiles.bombs_20K_gray_jpeg -> Dimension(20000, 20000),
    ExampleFiles.bombs_20K_gray_png  -> Dimension(20000, 20000),
    ExampleFiles.bombs_20K_rgb_jpeg  -> Dimension(20000, 20000),
    ExampleFiles.bombs_20K_rgb_png   -> Dimension(20000, 20000)
  )

  test("get sizes from input-stream") {
    files.foreach { case (uri, expect) =>
      val url = uri.toJavaUrl.fold(sys.error, identity)
      Using.resource(url.openStream()) { in =>
        val dim = ImageSize.get(in)
        assertEquals(dim, expect.some)
      }
    }
  }

  test("get sizes from stream") {
    files.foreach { case (uri, expect) =>
      val stream = uri.readURL[IO](8192)
      val dim    = ImageSize.get(stream).unsafeRunSync()
      assertEquals(dim, expect.some)
    }
  }
}
