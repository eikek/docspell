/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.files

import cats.effect._
import cats.implicits._
import fs2.io.file.{Files, Path}

import docspell.common.Glob
import docspell.logging.TestLoggingConfig

import munit._

class ZipTest extends CatsEffectSuite with TestLoggingConfig {
  val logger = docspell.logging.getLogger[IO]
  val tempDir = ResourceFixture(
    Files[IO].tempDirectory(Path("target").some, "zip-test-", None)
  )

  test("unzip") {
    val zipFile = ExampleFiles.letters_zip.readURL[IO](8192)
    val unzip = zipFile.through(Zip.unzip(8192, Glob.all))

    unzip
      .evalMap { entry =>
        val x = entry.data.map(_ => 1).foldMonoid.compile.lastOrError
        x.map { size =>
          if (entry.name.endsWith(".pdf")) {
            assertEquals(entry.name, "letter-de.pdf")
            assertEquals(size, 34815)
          } else {
            assertEquals(entry.name, "letter-en.txt")
            assertEquals(size, 1131)
          }
        }
      }
      .compile
      .drain
  }

  tempDir.test("unzipTo directory tree") { _ =>
    // val zipFile = ExampleFiles.zip_dirs_zip.readURL[IO](8192)
    // zipFile.through(Zip.unzip(G))
  }
}
