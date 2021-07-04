/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.files

import cats.effect._
import cats.effect.unsafe.implicits.global
import fs2.Stream

object TestFiles {

  val letterSourceDE: Stream[IO, Byte] =
    ExampleFiles.letter_de_pdf
      .readURL[IO](8 * 1024)

  val letterSourceEN: Stream[IO, Byte] =
    ExampleFiles.letter_en_pdf
      .readURL[IO](8 * 1024)

  lazy val letterDEText =
    ExampleFiles.letter_de_txt
      .readText[IO](8 * 1024)
      .unsafeRunSync()

  lazy val letterENText =
    ExampleFiles.letter_en_txt
      .readText[IO](8 * 1024)
      .unsafeRunSync()
}
