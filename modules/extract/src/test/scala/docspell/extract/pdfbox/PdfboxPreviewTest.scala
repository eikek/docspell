/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.pdfbox

import cats.effect._
import cats.effect.unsafe.implicits.global
import fs2.Stream
import fs2.io.file.Files
import fs2.io.file.Path

import docspell.files.ExampleFiles

import munit._

class PdfboxPreviewTest extends FunSuite {

  val testPDFs = List(
    ExampleFiles.letter_de_pdf -> "7d98be75b239816d6c751b3f3c56118ebf1a4632c43baf35a68a662f9d595ab8",
    ExampleFiles.letter_en_pdf -> "2bffbd01634525c6ce1fe477de23464e038055c4917afa41dd6186fe03a49f5b",
    ExampleFiles.scanner_pdf13_pdf -> "05ce4fd686b3d24b0e2d60df0c6d79b1df2338fcf7a6957e34cb4d11c65682b4"
  )

  test("extract first page image from PDFs".flaky) {
    testPDFs.foreach { case (file, checksum) =>
      val data = file.readURL[IO](8192)
      val sha256out =
        Stream
          .eval(PdfboxPreview[IO](PreviewConfig(48)))
          .evalMap(_.previewPNG(data))
          .flatMap(_.get)
          .through(fs2.hash.sha256)
          .chunks
          .map(_.toByteVector)
          .fold1(_ ++ _)
          .compile
          .lastOrError
          .map(_.toHex.toLowerCase)

      assertEquals(sha256out.unsafeRunSync(), checksum)
    }
  }

  def writeToFile(data: Stream[IO, Byte], file: Path): IO[Unit] =
    data
      .through(
        Files[IO].writeAll(file)
      )
      .compile
      .drain
}
